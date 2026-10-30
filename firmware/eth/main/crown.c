/* bioho: THE CROWN.
 * The swarm serves from a single locally-administered vMAC that the elected
 * leader wears on its W5500 (SHAR rewrite via ETH_CMD_S_MAC_ADDR). When
 * leadership moves, the new leader claims the vMAC and sets the crown's FIXED
 * static address on link-up; the gratuitous ARP lwIP emits then relearns the
 * switch CAM - same MAC, same address, new port, and serving survives any one
 * node's death. Followers keep their own identity and their own DHCP lease.
 *
 * SAFETY (we can only reach the fleet over this same wire):
 *  - every node BOOTS into its own identity (own MAC + own IP) = always OTA-able.
 *  - followers stay on their own identity; only the leader swaps to the vMAC.
 *  - if a crown claim gets no address within CROWN_CLAIM_TIMEOUT, revert to own
 *    identity so the node never strands itself.
 */
#include <string.h>
#include "esp_eth.h"
#include "esp_netif.h"
#include "esp_mac.h"
#include "esp_timer.h"
#include "esp_log.h"
#include "crown.h"
#include "blackbox.h"
#include "splice.h"
#include "serve.h"
#include "swarm_identity.h"
#include "swarm.h"
#include "logic.h"   /* bioho_claim_grace: a claimant mid-swap still counts as reachable */

static const char *TAG = "bioho_crown";

/* the crown: 0x02 = locally administered + unicast, "ACLD" (0x41 0x43 0x4c 0x44),
 * instance 0x01 - minted for this deployment; no factory ever issued it. */
static const uint8_t VMAC[6] = SWARM_VMAC_BYTES;

/* Bounds the claim itself - link back up and the address set - after
 * swap_identity(). The crown uses a static address, never DHCP: a timeout here
 * is a claim failure, not a lease failure. */
#define CROWN_CLAIM_TIMEOUT_US (10 * 1000000)
/* The swap stops and restarts the PHY: 1-3 s measured until the static address
 * is set. For this long a claimant still reads as holding an address, or its own
 * heartbeat tells the peers that just elected it that it is unable, and the
 * next id claims too - the 2026-10-23 cascade, three blades wearing the vMAC
 * inside three seconds (bioho_claim_grace). */
#define CROWN_CLAIM_GRACE_MS 5000

/* the crown's FIXED address - always reachable, whoever leads. The address and
 * gateway are deployment config from secrets.h (via crown.h). */
#define CROWN_NETMASK    "255.255.255.0"
#define CROWN_GW         BIOHO_CROWN_GW

static esp_eth_handle_t s_handle;
static esp_netif_t *s_netif;
static uint8_t s_own_mac[6];
static bool s_wearing;
static bool s_have_ip;
/* Our own lease, remembered: dhcpc_start() zeroes the address before asking,
 * so an abdicating blade sat at 0.0.0.0 for a full DHCP round trip and fell
 * out of the backend pool. The server holds the lease against this MAC -
 * re-apply it instantly; cold boots still DHCP normally. */
static esp_netif_ip_info_t s_own_lease;
static bool s_have_lease;
static int64_t s_wear_started_us;

const uint8_t *crown_vmac(void) { return VMAC; }

static volatile uint32_t s_current_ip;
void crown_set_ip(uint32_t ip) { s_current_ip = ip; }
uint32_t crown_get_ip(void) { return s_current_ip; }
bool crown_is_wearing(void) { return s_wearing; }
bool crown_has_ip(void)
{
    return bioho_claim_grace(s_wearing, s_have_ip, (uint32_t)(s_wear_started_us / 1000),
                             (uint32_t)(esp_timer_get_time() / 1000), CROWN_CLAIM_GRACE_MS);
}

void crown_init(esp_eth_handle_t eth_handle, esp_netif_t *eth_netif)
{
    s_handle = eth_handle;
    s_netif = eth_netif;
    esp_read_mac(s_own_mac, ESP_MAC_ETH);  /* the derived (base+3)|0x02 identity */
    ESP_LOGI(TAG, "own %02x:%02x:%02x:%02x:%02x:%02x | crown %02x:%02x:%02x:%02x:%02x:%02x",
             s_own_mac[0], s_own_mac[1], s_own_mac[2], s_own_mac[3], s_own_mac[4], s_own_mac[5],
             VMAC[0], VMAC[1], VMAC[2], VMAC[3], VMAC[4], VMAC[5]);
}

/* stop link, rewrite W5500 SHAR + netif MAC + hostname, restart -> re-DHCP as the
 * new identity. httpd listens on 0.0.0.0 so it keeps serving across the swap. */
static void swap_identity(const uint8_t mac[6], const char *hostname)
{
    esp_eth_stop(s_handle);
    esp_eth_ioctl(s_handle, ETH_CMD_S_MAC_ADDR, (void *)mac);
    esp_netif_set_mac(s_netif, (uint8_t *)mac);
    esp_netif_set_hostname(s_netif, hostname);
    s_have_ip = false;
    esp_eth_start(s_handle);
}

void crown_set_leader(bool i_am_leader)
{
    const swarm_member_t *self = swarm_self();
    if (i_am_leader && !s_wearing) {
        s_wearing = true;
        s_wear_started_us = esp_timer_get_time();
        ESP_LOGW(TAG, "WEARING THE CROWN - %s becomes the swarm's face", self->name);
        swap_identity(VMAC, "bioho");
    } else if (!i_am_leader && s_wearing) {
        /* close what we are relaying BEFORE the interface goes out from under
         * it. Otherwise every in-flight visitor gets a reset at the exact
         * moment the fleet is trying to look seamless. */
        splice_drain("dropping the crown");
        s_wearing = false;
        ESP_LOGW(TAG, "removing the crown - back to %s", self->name);
        swap_identity(s_own_mac, self->name);
    }
}

void crown_on_got_ip(void)
{
    s_have_ip = true;
    if (!s_wearing) {                       /* remember the lease we were given */
        esp_netif_ip_info_t got = {0};
        if (esp_netif_get_ip_info(s_netif, &got) == ESP_OK && got.ip.addr) {
            s_own_lease = got;
            s_have_lease = true;
        }
    }   /* own-identity DHCP lease arrived (the crown uses a static IP, set on link-up) */
}

/* called from the ETHERNET_EVENT_CONNECTED handler (link just came up). The crown
 * claims its FIXED static IP here (set while the netif is up so lwIP emits the
 * gratuitous ARP that relearns the switch on failover); own identity uses DHCP. */
static bool s_link_up;
static int64_t s_link_down_us;
#define CROWN_LINK_GRACE_US (6 * 1000000)   /* a relink takes 1-3 s; 6 s is not a bounce */

bool crown_link_up(void) { return s_link_up; }

void crown_on_link_up(void)
{
    s_link_up = true;
    s_link_down_us = 0;
    if (s_wearing) {
        esp_netif_dhcpc_stop(s_netif);   /* ok if already stopped */
        esp_netif_ip_info_t ip = {0};
        esp_netif_str_to_ip4(CROWN_STATIC_IP, &ip.ip);
        esp_netif_str_to_ip4(CROWN_NETMASK, &ip.netmask);
        esp_netif_str_to_ip4(CROWN_GW, &ip.gw);
        esp_netif_set_ip_info(s_netif, &ip);   /* static + gratuitous ARP */
        s_current_ip = ip.ip.addr;
        s_have_ip = true;
        ESP_LOGW(TAG, "THE CROWN IS LIVE - static %s, serving from the vMAC", CROWN_STATIC_IP);
    } else if (s_have_lease) {
        /* take our own address straight back - no discovery, no gap */
        esp_netif_dhcpc_stop(s_netif);
        esp_netif_set_ip_info(s_netif, &s_own_lease);
        s_current_ip = s_own_lease.ip.addr;
        s_have_ip = true;
        ESP_LOGW(TAG, "own identity restored instantly from the remembered lease");
    } else {
        esp_netif_dhcpc_start(s_netif);   /* first time up: ask properly */
    }
}

/* Claiming or dropping the crown deliberately bounces the PHY (esp_eth_stop/start
 * inside swap_identity), so a link-down is NORMAL for a second or two right after
 * a transition. Only a link that stays down means the wire is genuinely gone. */
void crown_on_link_down(void)
{
    if (s_link_up) {
        s_link_down_us = esp_timer_get_time();
    }
    s_link_up = false;
}

/* true only once the wire has been down long enough that it is not our own bounce */
bool crown_link_lost(void)
{
    if (s_link_up) {
        return false;
    }
    if (s_link_down_us == 0) {
        return false;   /* never been up yet - boot, not a loss */
    }
    return (esp_timer_get_time() - s_link_down_us) > CROWN_LINK_GRACE_US;
}

/* Give the crown back immediately. The election decides who takes it next; our
 * job is only to stop pretending we are reachable. */
void crown_abdicate(void)
{
    if (!s_wearing) {
        return;
    }
    const swarm_member_t *self = swarm_self();
    s_wearing = false;
    s_have_ip = false;
    ESP_LOGE(TAG, "ABDICATING - the wire is down, %s can no longer be the swarm's face",
             self ? self->name : "this node");
    swap_identity(s_own_mac, self ? self->name : "bioho");
}

/* Discovery is RETRIED until a lease lands - an address-less blade still
 * gossips serving=1 but cannot be routed to (refresh_backends needs ip!=0). */
#define DHCP_RETRY_US (8 * 1000000)
static int64_t s_dhcp_wait_us;

void crown_tick(void)
{
    /* Drop the crown the moment we cannot serve: a wearer that waits for the
     * ordinary election cycle is a black hole (empty backend set, solo gated
     * on serve_is_ready). The public face belongs to a node that can answer. */
    if (s_wearing && !serve_is_ready()) {
        const swarm_member_t *self = swarm_self();
        ESP_LOGW(TAG, "cannot serve while wearing the crown - dropping it now");
        blackbox_event(BBX_CROWN_OFF, 0, "not ready - dropped the crown immediately");
        splice_drain("cannot serve");
        s_wearing = false;
        swap_identity(s_own_mac, self ? self->name : "bioho");
        return;
    }

    if (!s_wearing && s_link_up && !s_have_ip) {
        int64_t now = esp_timer_get_time();
        if (s_dhcp_wait_us == 0) {
            s_dhcp_wait_us = now;
        } else if (now - s_dhcp_wait_us > DHCP_RETRY_US) {
            s_dhcp_wait_us = now;
            ESP_LOGW(TAG, "no DHCP lease %d s after dropping the crown - retrying discovery",
                     (int)(DHCP_RETRY_US / 1000000));
            blackbox_event(BBX_CROWN_OFF, 0, "no lease after abdication - retrying DHCP");
            esp_netif_dhcpc_stop(s_netif);
            esp_netif_dhcpc_start(s_netif);
        }
    } else {
        s_dhcp_wait_us = 0;
    }

    if (s_wearing && !s_have_ip &&
        esp_timer_get_time() - s_wear_started_us > CROWN_CLAIM_TIMEOUT_US) {
        const swarm_member_t *self = swarm_self();
        ESP_LOGE(TAG, "crown claim timed out (no link/address %d s after the swap) - "
                      "reverting to %s to stay reachable",
                 (int)(CROWN_CLAIM_TIMEOUT_US / 1000000), self->name);
        s_wearing = false;  /* election re-drives us if leadership changes again */
        swap_identity(s_own_mac, self->name);
    }
}
