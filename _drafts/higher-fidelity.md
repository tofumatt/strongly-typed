---
layout: post
title: "Higher Fidelity"
description: "The beginnings of a better way to build web apps."
tags: [open source, open web apps]
image:
  feature: mozilla-is-my-dinosaur.jpg
share: true  
---

I started work on an [HTML5 podcast app][] [well over a year ago][], but I wasn't pleased with how it turned out. I've been writing "reference apps" for Mozilla for the past year or so and I have been frustrated with the process of writing HTML5 web apps compared to my experience using Rails, Django, and even Xcode. I've learned to use frameworks like Backbone or Ember and tools like Grunt or Yeoman, but I've found every solution to be lacking and piecemeal. I wanted to rewrite the Podcasts app. In doing so I think I've pieced together a set of tools that makes writing non-trivial, offline-first web apps easier and more like I remember writing Rails apps.

First off I'd like to walk through the differences between my old app and new one, but afterward I'd like to talk about the tooling I've extracted from building Podcasts that I hope other developers can take advantage of to write their own Open Web Apps for Firefox OS.

[HTML5 podcast app]: https://github.com/mozilla/high-fidelity/
[well over a year ago]: https://github.com/mozilla/high-fidelity/commit/6f023aa399b3d7b773d0f41c182d9f7b328a6184

## UI Improvements

Thanks to [Brick][], the UI of the Podcasts app is much improved.

[Brick]: https://mozbrick.github.io/
