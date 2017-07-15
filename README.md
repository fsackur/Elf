# Elf

A sketch for an automation engine that will run a script from a script library on multiple target computers.

Interfaces with a configuration database that holds target computer IP addresses and credentials.

Uses event-driven design for performance.

# Open-source?

This project will form the basis of proprietary software. I will not be completing the implementation in the public domain.

This is starting with a very restrictive license. You can't do much with this until I've got my proprietary fork started. The reason is to prevent inadvertently granting rights to the proprietary product.

After that, I may look at attaching a copyleft license.

Reach out to me if you'd like to discuss.

# Design goals

- [ ] High-performance
- [ ] Only allows script from the library to be run
- [ ] Easy to develop script for the library
  - [ ] Minimises platform-specific requirements
- [ ] Easy to debug script as it's running on target computers
- [ ] Returns alternate data streams
- [ ] Builds dependencies and transfers them to target computers
- [ ] Supports a CI/CD pipeline
- [ ] Attempts connection to target computers with WinRM
  - [ ] Fails back to PSEXEC
- [ ] Supports target computers running Server 2008 RTM and PowerShell 2

# Credits
Shout out to Jim Moyle ([@JimMoyle](https://twitter.com/jimmoyle)), who helped enormously with his content on:
- Event-driven programming in PowerShell
- Debugging runspaces

Jim's YouTube channel is [here](https://www.youtube.com/channel/UCjUtHlDsAIasXffpiORfwUA)