---
title: "Replacing RedPi"
date: 2026-06-14
summary: "RedPi became infrastructure. Lenny is faster, boring, and rebuildable."
cover: microsd.jpg
tags:
  - code
  - docker
  - terminal
---

RedPi was supposed to be disposable.

It is a Raspberry Pi 3B in a red case, sitting on a wire rack under my desk. It started with small jobs, then quietly became house infrastructure: Pi-hole, Gluetun, Transmission, MiniDLNA, custom services, and the clients that drive my [mainframe-style weather display](../mainframe-display/).

I use the media stack once in a while. The weather display sits in my direct view every day. That changes the emotional category. RedPi stopped being a toy and became something I would miss.

I also wanted a better place to play with server-shaped projects. [agent-control-plane](https://github.com/rhew/agent-control-plane) does not belong on my laptop forever, and Chuck has been messing with Hermes too. I needed a lab that was not also my daily machine.

Nothing failed. That was the point.

I wanted to prove I could rebuild RedPi without losing data or poking the working server. The sensible plan was a fresh SD card.

[A tiny boot drive](https://commons.wikimedia.org/wiki/File:MicroSDXC.64GB.P1127589.jpg) is charming until it starts costing real money. A Samsung Pro Endurance card lists around $12, but the ones I found at Amazon and Newegg were closer to $55. For $165, I found a Lenovo ThinkCentre M80q with a Core i5-10500T, 256GB SSD, and 16GB of RAM.

Three SD cards, or one real server. That was not a hard call.

The listing said no OS and no power adapter, which sounds like a warning until it is exactly what you want. I already had the adapter. I did not want Windows. The little Lenovo could go straight into the [network rack](../network-rack/), visible there in its current spot, and become `lenny`.

## Boring Wins

The OS choice was more interesting than the hardware. I wanted a simple, secure container host: SSH keys, security updates, a small attack surface, and no drama.

openSUSE MicroOS tempted me. Transactional updates and reboot-based patching sound right for an appliance. Fedora CoreOS and Flatcar have the same appeal, but they feel built for fleets and clusters. I had one box.

[Debian](https://commons.wikimedia.org/wiki/File:Debian-OpenLogo.svg) won by being boring.

Debian minimal is familiar, well documented, easy to automate, and unlikely to turn the operating system into the project. Ubuntu Server would have worked too, but Debian gave me fewer ecosystem opinions to work around.

## Rebuildable

The real upgrade is not ARM to x86, SD card to SSD, or tiny board to tiny server. The real upgrade is that the server is now deployed from code.

The recipe lives in [server-infra](https://github.com/rhew/server-infra). Ansible handles the base machine. Docker Compose handles the services. The machine can be replaced.

That matches how I already ran these services. Docker and Compose carried most of the application work, so Debian only had to be the boring base layer under a version-controlled stack.

Lenny is running now. RedPi did its job well enough that I had time to replace it calmly, which is the best ending a little home server can get.

The win is not speed. The win is rebuildability.

Next I want the hosted `rhew.org` web server in the same shape: documented, automated, and replaceable.
