#pragma once

/* The crown's FIXED address - the one the router forwards to. It must sit
 * outside the router's DHCP pool. Like every other deployment specific, it
 * lives in the gitignored secrets.h, never in the tree. */
#include "secrets.h"
#ifndef BIOHO_CROWN_IP
#error "add BIOHO_CROWN_IP (the crown's reserved LAN address) to secrets.h"
#endif
#ifndef BIOHO_CROWN_GW
#error "add BIOHO_CROWN_GW (the LAN gateway) to secrets.h"
#endif
#define CROWN_STATIC_IP  BIOHO_CROWN_IP
#include <stdbool.h>
#include <stdint.h>
#include "esp_eth_driver.h"
#include "esp_netif.h"

/* The crown: the swarm's single immortal wire identity (the vMAC). The elected
 * leader wears it; followers keep their own identity. See docs/firmware/node_swarm.md. */

void crown_init(esp_eth_handle_t eth_handle, esp_netif_t *eth_netif);
void crown_set_leader(bool i_am_leader);  /* election calls this on a leadership transition */
void crown_tick(void);                    /* called periodically - drives the safety fallback */
void crown_on_got_ip(void);               /* called from the eth GOT_IP handler */
void crown_on_link_up(void);              /* called from the eth CONNECTED handler */
void crown_on_link_down(void);            /* called from the eth DISCONNECTED handler */
const uint8_t *crown_vmac(void);          /* the 6-byte vMAC, for logging */

/* the node's current eth IPv4 (esp_ip4 .addr, 0 if none) - shared into heartbeats */
void crown_set_ip(uint32_t ip);
uint32_t crown_get_ip(void);
bool crown_is_wearing(void);
/* Do we currently hold an address at all? A blade between the crown and a fresh
 * DHCP lease is reachable by nobody, and must not claim to be serving. */
bool crown_has_ip(void);
bool crown_link_up(void);
bool crown_link_lost(void);   /* down for longer than a transition bounce */     /* Ethernet PHY link state - the data plane's own opinion */
void crown_abdicate(void);    /* drop the crown now (link died under us) */
