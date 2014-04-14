---
layout: post
title: "Hipster UX and Vintage Data"
description: "A trick to make your web app fast without doing anything."
tags: [apps, javascript, mozilla, web]
image:
  feature: loading.jpg
share: true
---

As web developers, we too often wait until we have _all of the data_ before we
render _any_ of it. And because we're used to having fast access to our data
sources (memcache, MySQL, redis) on the server, we're sticklers for wanting
the **very latest data**. When you can make a 10ms request to memcache, why
display content that's even a bit out-of-date? But how often has your Twitter
client displayed an old avatar or user bio? We can do this with our web apps'
data and _drastically_ improve the speed and user experience of our apps.

We've spent over a decade writing code on a server that had to send
an entire page or piece of data down the wire at once. But these days we're
writing client-side apps, and we should rethink how we render data in our
interfaces. We need only do two things to start building more responsive,
delightful apps: **embrace stale caches** and **render smaller pieces**.

If you're building apps that interact with an API, be it your own or someone
else's, you should embrace the world of [offline storage in web apps](http://mozilla.github.io/localForage).
You'd be surprised how fast your app can be when it's spending time getting
data from IndexedDB or WebSQL instead of an API hundreds of milliseconds away.

### An Obvious Caveat

I'm going to talk about apps that interact with a REST API like Basecamp,
Foursquare, or Twitter. These concepts won't apply as much to something like
a chat app where things are happening instantly, but some concepts still apply.

## Expiration Dates

<a href="http://flickr.com/photos/orinrobertjohn/158456029" class="photo-link" target="_blank"><img src="{{ site.url }}/images/best-before.jpg" alt="Best before date on a glass bottle." title="(Photo credit: Orin Zebest)" class="photograph"></a>Given the choice between old data and no data: I would rather the stale data. But it's also important to question our assumptions
about what makes data _actually_ stale. Checking to see if our cache is
out-of-date on a **server** is generally very fast. Or we can cache data as we
build it and expire it in our models. On the client, we need to make a request
to a server to check for new info. _Every time._ This is very expensive, and
even a fantastic route to an API server will mean a few hundred milliseconds
round-trip. This is long enough that users will
[notice a delay](http://blog.codinghorror.com/performance-is-a-feature/).

While we can gather our data very quickly on the server, we only have one
opportunity to send it down the wire. The request/response cycle means once we
send data: it's over. Not so for our client apps; we can fetch many smaller
pieces of data, or refresh only what we need. For instance, in
[_Around_](http://around.lonelyvegan.com/beta), information about a venue on
Foursquare--its name, address, and opening hours--are updated only if it is
more than a day old. But where your friends are checked in is polled every
few minutes (or every time you close and open the app), as it's data that needs
to be much more timely.

Because _Around_ never bothers to update recently-fetched venue information,
and caches every venue it loads, search results are blazingly fast, and you
can check up on any place you've already looked at, even while you're offline.
And if you _do_ need to update your info, don't throw away cached data if it's
stale; instead: load the stale cached data while you make an API request to
get the new stuff. Doing this increases how fast our apps _feel_, and the
perception of an app that is never "doing nothing" or "just waiting" is key.

Finally: even when you're online, the difference between making an API
request and loading something from device storage is a matter of hundreds--if
not sometimes _thousands_--of milliseconds your app is in a loading state.

So take advantage of offline storage in your app to cache every conceivable
bit of data. Most web APIs consumed via JavaScript are already JSON, so cache
the API request as JSON and mark it as the response from a particular URL and
with a particular timestamp. That tiny abstraction should let you wrap up a
tonne of caching work very easily.

## Taking Smaller Bytes

Thanks to asynchronous JavaScript APIs, we can fetch many
smaller pieces of data at once, and we can populate pieces of the DOM as we get
data, rather than showing an empty screen until everything is available. We're
already caching the hell out of API responses [using client-side storage](http://mozilla.github.io/localForage), but remember too that 
Doing this increases how fast our apps _feel_, even if the time to render all
the content is the same (or even slightly _faster_).

At Mozilla, I've been working on an HTML5 Foursquare app named
[_Around_](http://around.lonelyvegan.com/beta) for the past six
months. The app's concept is simple: be a full-featured Foursquare client that
runs on any modern browser. It's optimized for Firefox OS and Firefox for
Android. I think it's a slick client, and it shows off what web apps, in
particular _hosted web apps_ with no proprietary APIs or hacks, can do.

_Around_ only makes requests to Foursquare's API on the first
request for something like a venue. Once any checkin, tip, user, or venue has
been loaded, we cache that data using [localForage](http://mozilla.github.io/localForage)
and display the cached data to the user **no matter what**. Even if the cached
data is expired, we'll show it while we fetch new, updated data.
All of this caching (and some pre-fetching) allows you to explore a
neighbourhood even after you've gone offline, provided you're had a look around
at some point beforehand.

## Cache All the Things!

If we take it one step further, we can cache things not stored in models. For
a Foursquare app, the chief piece of data we need to have handy is a user's
location. Geolocation requests are not only slow, but they're a _huge_ battery
drain. So we request a very precise set of coordinates using the
[Geolocation API](https://developer.mozilla.org/docs/WebAPI/Using_geolocation)
and cache them for several minutes. We also cache nearby locations and sets of
search data; if the user is in the same spot and taps the "explore" button, we
don't need to send a request to Foursquare for the same coffee shops nearby
every time they load that screen.

This means that the geolocation results of my "slow web app" is _considerably
faster than native implementations_.

All of this makes _Around_, a web app running in Safari, feel faster than
the native iOS Foursquare app in many ways on my iPhone.

## The Takeaway

I'm not advocating tossing cache invalidation aside, but I am advocating for
fewer network requests--even for apps like a Foursquare client that interact
with a remote service. Latency on mobile networks are high and speeds aren't
LTE everywhere. Mozilla is looking to deploy a $25 smartphone which will only
support EDGE networking, so it's important to conserve resources for the next
group of smartphone users, who certainly won't be on the same kind of network
as those in San Francisco or Berlin.

So what can you do? Start with these suggestions:

* Whenever you request data from an API: **cache it**.
* Don't be afraid to display old data, especially while you fetch new data.
* Only chastise the user for being offline if you have _no_ data to show them.
  If they just want to read restaurant reviews while they're offline: let them.
* Don't worry a user with where data comes from. Populate your app as you get
  the data, not once you have every last drop.
* Never prevent app interaction because you're loading data.
* If you're able to post data in the background, do it! Let the user browse
  through your app while they're uploading a photo on another thread; don't
  display an awful modal window.

If one of the complaints about web apps is that they "aren't as responsive as
native apps", I think we, as web app developers, are partly to blame. Let's get
away from our `cgi-bin` roots and embrace the thick-client, thin-server world.
