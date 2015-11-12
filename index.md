---
layout: project
title: BadgeHacker
permalink: /projects/badgehacker/

tagline: Customize your badges fast
excerpt: Deploy the Parallax Hackable Electronic Badge at your event without ever having to touch
         a line of code.

type: project
apptype: tools

program: BadgeHacker
repo: https://github.com/parallaxinc/BadgeHacker/releases
version: 0.1.3
image: screenshots/badgehacker.png

links:
  Source Code: https://github.com/parallaxinc/BadgeHacker
  Issue Tracker: https://lamestation.atlassian.net/browse/BADGE
  Change Log: https://github.com/parallaxinc/BadgeHacker/releases

platforms:
  -  name: Windows
     suffix: amd64.exe
     version: '0.1.3'

  -  name: Mac OS X
     suffix: amd64.dmg
     version: '0.1.3'

  -  name: Linux
     suffix: amd64.deb
     version: '0.1.3'

  -  name: Raspberry Pi
     suffix: armhf.deb
     version: '0.1.3'

---


<div class="row">
  <div class="col-sm-6 col-md-6">
    <h2>About</h2>
    <p class="lead">{{ page.excerpt }}</p>
  </div>
  <div class="col-sm-6 col-md-6">
   <img src="screenshots/badgehacker.png" />
  </div>
</div>
