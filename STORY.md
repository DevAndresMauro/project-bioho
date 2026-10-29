## serving a website from six ESP32 microcontrollers on a shelf

I grew up curious about how things worked and started disecting systems and technology at a young age, and i am fortunate enough that my parents were supportive (as long as i didnt break anything, but i had some "casualties"). and my father always tried to find ways to feed my curiosity. Thats how i ended up doing my highschool at the ITIDA, which is a public school in Soledad, Atlántico, Colombia. that focused in specialized technical industrial education. which exposed me to a variety of areas, electronics won my heart then. 

I am an electronics and systems engineer by training. however, life took me to a different professional path, so electronics/programming and software stayed as a fun hobby. Whenever i found something interesting i would just try to go for it, from FPV drones to a cloud lab, any project built was a challenge, an activity that taught me something new while helping me keep my skills in electronics, programming, etc. and finding a project that helps me tap into those areas is amazing.

This swarm is one of those builds.

I never actually had a portfolio website, a blog, or anything of that sort, but if i tried it, i knew i would try to go for something different, i could have done something simple, just _a website_ from any of the VMs i had set up in the past, or a Raspberry Pi, even a free tier on a cloud provider would have probably been a quick and prudent way of doing it...

But what's the fun in that?

Thats what made this project stand out to me:

1. What if... the website is hosted on a 5x3cm microcontroller board weighing under 20 grams?
2. It wouldn't scale, though? Now we're talking, let's make it four microcontrollers then!
3. How do we distribute the work then? Let's make one of them tell the others what to do!
4. And how would I know what's going on in my own system? Let's get a display and render things on it!
5. What about knowing that everything's okay quickly? Fine, let's add a bright LED rail to color-code the state!
6. Tiny screen is a tiny window for a lot of data, though? Right, let's buy a Bigger Screen and show All The Data there!
7. But the screens don't have Ethernet! How would they even learn about anything in the fleet? Indeed, so we'll make the fleet talk to each other over radio instead!
8. How would I deploy any changes for this system? Let's do it over the air and make it safe, too!
9. Where would the four cimarrones reside? On one printed plate, the bohío.
10. The screens are useless in a closet though. Also, what about the power supply, and networking, in this heat? One printed shell holds the whole machine. That shell is the rack. Two 50 mm fans will sit on the lid and blow out. There is no intake fan.

As a result, https://projectbioho.com is served from six ESP32-S3 microcontrollers on a shelf
in a flat, somewhere in Berlin.

No CDN in front, no Cloud behind, no hosting provider, no Raspberry Pis, and most definitely no hardware load balancers anywhere in the building. 
The whole machine, screens and fans included, draws about 22 watts.
The primary fleet serves the website and terminates TLS on 240 MHz chips, load-balances across itself with a bespoke L4 TCP splicer, monitors itself, and heals itself.
It survives pulling any plug in it, including the leader's, recovering in under four seconds.

Whether the fleet will be able to survive visitors this thread - only time will tell. 
I must ask the readers to be forgiving and gentle with it - there is a very real ceiling on how much TLS termination an ESP32 is able to physically do.
Under nominal pressure, a fresh HTTPS connection costs ~650 ms for a P-256 handshake, with a ~325 ms TTFB.
Spread across the existing fleet, ~2.9-3.0 new visitors per second is where the first connection drops would start.
Once your browser is in, however, requests over the warm connections return within ~40-60 ms, and the fleet does okay at ~40-50 RPS.
Beyond ~100 RPS the network throughput of a single splicer blade starts becoming a limiting factor. 

Under severe backpressure, the website shouldn't cascade and fall over: it will serve at its ceiling and gradually shed the excess.
If the site is slow when you try it, chances are it's not because the machines are struggling, but rather because you're sitting in a queue behind other visitors.

Here is what it took to get there.

## Original Project

I have to give credit to Kyrylo Novotarskyi, as his original project [ivan-bohun](https://github.com/Novotarskyi/ivan-bohun) was practically a blueprint for what i ended up building
You can read the original projects story, and support his cause by going to his ESP32 Hosted webiste https://kyrylonovotarskyi.com/

Inspired by his story, i set out to build a version of the project with my spin on it.

## Project Biohó

A good story must have its own lore.
The fleet is **Project Biohó**, named for Benkos Biohó, who broke his chains and built Palenque, a free town the empire could not take.  
The whole design is that same refusal: no landlord, no cloud, one identity the machines pass between themselves.  
The elected leader is the **capitán** and wears the **crown**. The blades that answer are **cimarrones**. The small screen is the **vigía**, the wide screen is the **cabildo**. The plate the four cimarrones share is a **bohío**, and the shell around the whole machine is the rack, the fortress, if you will.


## Key rule of thumb

There was only one hard constraint in this project:  **the serving path is
microcontrollers only.** 
No single-board computer, no mini PC, nothing with a Linux kernel anywhere near a request.
This is what made the whole thing interesting to me.
Arguably, using ESP32-S3 microcontrollers to serve HTTPS traffic en-masse is not the sharpest idea.
However! It is surely doable, because the tiny cute ESP32-S3s can do a lot!
In raw integer work, one is roughly a match for a mid-90s desktop CPU.
And if people have famously run Doom on these chips, surely we'd be able to serve a page or two as well!
And we'll most definitely do it, because we can and for the sake of it!

The serving blades ended up being, rather accidentally, four LILYGO T-ETH-Lite boards, costing about £12 (~$16) each: an ESP32-S3 with a
W5500 wired-Ethernet chip.
Everything else in the shell exists to power them, connect them, or tell me the truth about them.

## Shapeshifting Problem 

The interesting problem in a fleet like this is not necessarily about serving itself, but rather about figuring out **who
answers**.

Four blades share one public identity: a vMAC address, which I've locally
administered, and one LAN IPv4 address that the router
forwards port 80 and 443 to. 
Whoever in the serving fleet wins the election writes that MAC into its 
W5500 and announces it with a gratuitous ARP. Failover is fast precisely
because nothing upstream learns anything: the router's ARP entry never
changes, only the local switch relearns one port. The W5500 makes the trick
possible by having no factory MAC at all.
Instead, the host must program one, which, ironically, turned a nuisance into a key design feature.

The election itself runs over the ESP-NOW encrypted radio protocol and off the wire. This means a
cable or a switch failure cannot split the brain that decides who owns the
cable. 
The leader election mechanics are deliberately simple: 
the lowest-numbered blade that is alive on the radio, healthy on the wire, and is actually able to serve - leads.
Determinism often beats cleverness hands-down, and this case is no exception.

## The leader does not serve
Initially, the elected blade served every request while three blades
idled. 
However, having active hardware sitting there idling just for the sake of failover didn't feel right. 
To make use of it all, the fleet leader now acts as a **layer-4 TCP splicer**: it accepts your connection
on 443 and relays raw bytes to whichever blade has the fewest connections in
flight, never terminating TLS or parsing HTTP. The encrypted session
runs from your browser straight past the balancer to a downstream serving blade which answers on a port that is never forwarded.

The balancer is an elected role that moves between blades. Every blade
carries both programs, and which one it runs is decided by the election.
The splicer rebuilds its set every
second from the radio gossip, taking whoever is alive, serving, and holding
an address. Kill the leader, and the next blade takes the crown and balances to
what remains. Kill all but one and the survivor splices to its own server
over loopback: the ladder ends at the original single-blade site.

Misbehaving backends go on a bench: accept a connection and return nothing
three times, and you sit out 15s, doubling up to 240s. Once a blade has been
benched, one more silent accept is enough to put it back. The blade is
forgiven completely if a single byte is returned. 
Hard lesson learned while implementing: the bench should **only** decide who gets the next visitor, never **whether** there is
one to receive, otherwise a fully benched fleet will turn visitors away forever. 
Now, in the case where every downstream backend becomes suspect, one is going to be tried anyway.

## Blades that prove their own health

The nastiest bug this fleet ever had was a blade whose TCP stack wedged
while everything else stayed alive. It gossiped on the radio, held its link,
reported 'serving', and ate real traffic for hours - because the 'serving' flag was set at boot and never re-examined.
The flag got eventually replaced by two mechanics. 
1. Every blade now opens a TCP connection to its own public port every 7s. On two consecutive failures, the blade reports
itself out, leaves the election, and the balancer benches it within about ~2s. Six failures and the blade crashes itself **on purpose**, followed by a clean reboot attempt. A forced deliberate
crash felt like the sensible path allowing the blade to write a recoverable coredump naming the exact task its server was stuck in to troubleshoot.
2. Separately, the balancer judges backends only by what
comes back from them, independently of their self-reported state.

Fixing this bug was the toughest firmware bit of this project. 
The root cause, in the end, was quite typical for a person who doesn't __really__ know C well:
a `break` statement that was intended for an `if` bound to the enclosing `for` loop instead - which is
exactly what `break` does in C, just not what I meant. The relay task returned. 
I have subsequently also learned that FreeRTOS treats a relay task returning as fatal :)

## The Metal

The whole project is best described as one massive cascade of failures.
When the LILYGO blades arrived, the question was how to power them.

A LILYGO T-ETH-Lite board does have an Ethernet port. And I have assumed that, technically, Ethernet should be able to draw some current to power the tiny thing, right?
Well, yes, in theory, but no - not this port and not on this board it can't! 
Throwing away four perfectly good microcontrollers felt like a waste, so let's order a pack of USB-C breakout ports!
So how do we connect the two? With some wires, right? Absolutely!

The blades are wired with four soldered tails each, by an electronics technician, and the unused pins are left bare.
The soldering and the wiring quickly turned my work desk into a wired mess.
To compress space, the four cimarrones share one bohío: a printed plate on the switch, RJ45 noses toward the rear. The shell around that stack is the rack. It holds the switch, the power brick, the fuse board, the bohío, and both screens. Two 50 mm exhaust fans will sit on the lid. There is no intake fan.

Networking is an eight-port HPE OfficeConnect 1420 that uplinks to the home router, which forwards exactly two ports to the
crown's address and nothing to anything else. The admin plane, the OTA door, and the backend port exist only on the LAN.

Power is a Mean Well GST60A05-P1J, 5 V at 6 A, into a stripboard. Eight fused
branches leave it: six USB-C sockets, four for the blades and two for the screens, and two 2-pin screw terminals for the lid fans. The fans
are not fitted. With them on, the machine draws about 22 W of the brick's 30 W. Without them it sits a couple of watts under that, on two wall plugs: one for the brick, the
other for the switch.

## The witnesses

The machine is very much physical, so the observability stack is too.

A six-pixel LED rail sits in a slot on the shell's front wall, one pixel per
member, driven through a separately built level shifter circuit.
The reason I needed one is that the ESP32's 3.3V data line is
out of spec for an LED strip expecting 5V.
Lost is red, and red wins every argument.
A blade that is booting blinks white, fast. A release blinks white, slow.
After that, the steady colours: the capitán gold (`#e6c229`), a serving cimarrón faint green, a benched blade solid white, the vigía deepest blue, the cabildo deepest purple.
Open an OTA window and the whole rail blinks cyan, slowly.
The vigía's own pixel does not blink. Blue while any heartbeat is heard, red when the radio goes silent.

The 2.8" screen is the **vigía**: the crown's address and vMAC, then the live roster, role, signal bars, served counts, uptime, radio-loss, fleet availability, and which image is running on the glass.
A small copy of the six pixels sits on the screen too, so the rail can be read from the side the LEDs do not face.
The vigía drives the rail.

The 4.3" touch panel is the **cabildo**, a witness, not a blade. Four tiles.
The first is mission control: the node cards, a fleet chart, the chronicle (the chip latches why it died in a register that survives reset, and the line names that cause and how long the member had lived), and the reign records.
Then the ledger: every HTTP 200 above the refusals, per code, per blade.
Then the radio: the last 45 seconds of gossip, with a marker where a heartbeat was missed.
The fourth tile is the website itself, baked to RGB565 into its own flash partition (12.19 MB in the table), scrollable under a finger.
I built that page to learn a bit about LVGL. It stayed, because the glass should be able to hold the page the fleet serves.

None of the witnesses poll the fleet. The screens only listen, on the same encrypted
radio, hearing the same 1 Hz heartbeats as everyone else.

## Updates that cannot brick the fleet

Early on, bad config updates bricked the fleet's update path itself on multiple occasions, making the nodes recoverable only by hand via USB-C.

To make updates less risky, deployments now run on followers first, leader last, and every blade holds a new image
**on trial**: it must survive 90 seconds of continuous serving within a 5min deadline, otherwise the bootloader rolls back to the previous slot.
The screens have no Ethernet. A four-second touch joins the flat's WiFi and opens the same door, and a new image on a screen has to stay up and hear a peer for 60 seconds inside that same 5min, or the bootloader rolls it back.

Hard lesson re-learned: a release must never brick its own delivery path.

## Who built it

Claude did most of the typing on this project.

To my surprise, it proved much less capable at this kind of software than I expected, and it performed **extremely poorly** at designing anything for the physical world. Model tier mattered more than I would have guessed, too: Fable 5 could mostly keep up with the engineering, while dropping down to Opus regularly cost three steps back for every step forward.

Still, it types much faster than I do, so we made it work. The division of labour we've settled on: I decide what is true and what ships. Every measurement came off my bench, every disaster above happened to my actual hardware, and the solder burns are mine.

The whole build is open source in this repository. It contains the firmware for all three images, the OpenSCADs, various tooling, and a comprehensive build guide that starts at the first solder joint and ends with a fleet holding an election.

The living proof is the website itself: https://projectbioho.com

The roster at the top of the page is an actual live status of the setup sitting on my desk.
