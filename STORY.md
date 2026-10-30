## serving a website from six ESP32 microcontrollers on a shelf

I grew up curious about how things worked and started disecting systems and technology at a young age, and i am fortunate enough that my parents were supportive (as long as i didnt break anything, but i had some "casualties"). and my father always tried to find ways to feed my curiosity. Thats how i ended up doing my highschool at the ITIDA, which is a public school in Soledad, Atlántico, Colombia. that focused in specialized technical industrial education. which exposed me to a variety of areas, electronics won my heart then. 

I am an electronics and systems engineer by training. however, life took me to a different professional path, so electronics/programming and software stayed as a fun hobby. Whenever i found something interesting i would just try to go for it, from FPV drones to a cloud lab, any project built was a challenge, an activity that taught me something new while helping me keep my skills in electronics, programming, etc. and finding a project that helps me tap into those areas is amazing.

This swarm is one of those builds.

I never actually had a portfolio website, a blog, or anything of that sort, but if i tried it, i knew i would try to go for something different, i could have done something simple, just _a website_ from any of the VMs i had set up in the past, or a Raspberry Pi, even a free tier on a cloud provider would have probably been a quick and sensible way of doing it...

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

As a result, https://projectbioho.com is served from six ESP32-S3 microcontrollers on a shelf in a flat, somewhere in Berlin.

No CDN in front, no Cloud behind, no hosting provider, no Raspberry Pis, and most definitely no hardware load balancers anywhere in the building. 
The whole machine, screens and fans included, draws about 22 watts.
The primary fleet serves the website and terminates TLS on 240 MHz chips, load-balances across itself with a bespoke L4 TCP splicer, monitors itself, and heals itself.
It survives pulling any plug in it, including the leader's, recovering in under four seconds.

Under severe backpressure, the website shouldn't cascade and fall over: it will serve at its ceiling and gradually shed the excess.
If the site is slow when you try it, chances are it's not because the machines are struggling, but rather because you're sitting in a queue behind other visitors.

Here is what it took to get there.

## Original Project

I have to give credit to Kyrylo Novotarskyi, as his original project [ivan-bohun](https://github.com/Novotarskyi/ivan-bohun) was practically a blueprint for what i ended up building
You can read the original projects story, and support his cause by going to his ESP32 Hosted webiste https://kyrylonovotarskyi.com/

Inspired by his story, i set out to build a version of the project with my spin on it.

## Project Biohó

Im from the northern part of colombia, and much like the rest of my country, we have a lot of history. I wanted soething that would reflect the idea of this project, the rebelin against the system, so chose Palenque, but i did have to make one or 2 choices in the namings, ill let you discover them yourself.

The fleet is **Project Biohó**, named after Benkos Biohó, who broke his chains and built Palenque, a free town the empire could not take.  
The whole design is that same refusal: no landlord, no cloud, one identity the machines pass between themselves.  
The elected leader is the **capitán** and wears the **crown**. The blades that answer are **cimarrones**. The small screen is the **vigía**, the wide screen is the **cabildo**. The plate the four cimarrones share is a **bohío**, and the shell around the whole machine is the rack, the Palenque.

## The Palenque 

Since the original project painted a good picture of what to expect and laid the ground work of the potential pitfalls, i tried to follow the blueprint while thinking of a few improvements, in general, the hardware stayed the same, with the same compromises, 4 LILYGO T-ETH-Lite boards that needed a USB-C breakout, and 2 screens also powered through USB-C.  

The changes were mainly the power delivery and the "Rack"

Power is driven by a Mean Well GST60A05-P1J, 5 V at 6 A, plugged into a custom stripboard.  
Eight fused branches leave it: six USB-C sockets, four for the blades and two for the screens, and two 2-pin screw terminals for the lid fans.

The fans are not fitted yet. With them on, the machine draws about 22-25 W of the brick's 30W. Without them it sits a couple of watts under that, on two wall plugs: one for the brick, the other for the switch.

Networking is an eight-port HPE OfficeConnect 1420 that uplinks to the home router.  
The admin plane, the OTA door, and the backend port exist only on the LAN.

To compress space, the rackmate was replaced by a 3d printed enclosure, and the four cimarrones share one bohío: a printed plate on top of the switch, RJ45 ports facing the rear. the enclosure holds the switch, the power brick, the fuse board, the bohío, and both screens. Two 50 mm exhaust fans will sit on the top lid. There is no intake fan.

## Key takeaways

Just like the original, the whole build is open source in this repository. It contains the firmware for all three images, the OpenSCADs, STLs, various tooling, and a  build guide that starts at the first solder joint and ends with a fleet holding an election.

The living proof is the website itself: [https://projectbioho.com](https://projectbioho.com)

The roster at the top of the page is an actual live status of the setup sitting on the shelf.
