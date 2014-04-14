---
layout: post
title: "Hipster UX and Vintage Data"
description: "A trick to make your web app fast without doing anything."
tags: [apps, javascript, mozilla, web]
image:
  feature: loading.jpg
share: true
---

Given the choice between old data and no data, I know which I'd rather.<br>
Let's talk about the user experience of client apps and the actual importance
of "fresh data". In caching every bit of data from an API, then using that data
as much as possible--instead of making essentially duplicate requests--I made
an incredibly fast and usable app. I think more apps could benefit from
ditching their fear of missing out, and embracing speed over canonicity.

One of my most loathed experience in the world of web apps is any kind of blank
or baren loading screen. I get why, as web developers, we wait
until we have _all of the data_ before we render any of it. We've spent over a
decade writing code on a server that had to send an entire page or piece of
data down the wire at once.

But now we're writing client-side web apps, and there's no reason to
[leak our abstractions of where data comes from](http://www.joelonsoftware.com/articles/LeakyAbstractions.html)
to our users. Thanks to asynchronous JavaScript APIs, we can fetch many
smaller pieces of data at once, and we can populate pieces of the DOM as we get
data, rather than showing an empty screen until everything is available. We
can also cache the hell out of API responses [using client-side storage](http://mozilla.github.io/localForage). This lets us render parts of a page at a time, rather than
wait for every last bit of data to be ready before we display _anything_.
Doing this increases how fast our apps _feel_, even if the time to render all
the content is the same (or even slightly _faster_).

We can be smarter about how we display data. Let's take a real-world example:
Mozilla's HTML5 Foursquare client, _Around_.

## _Around_ and the Foursquare API

I've been working on an HTML5 Foursquare app named
[_Around_](http://around.lonelyvegan.com/beta) for the past six
months. The app's concept is simple: be a full-featured Foursquare client that
runs on any modern browser. It's optimized for Firefox OS and Firefox for
Android. I think it's a slick client, and it shows off what web apps, in
particular _hosted web apps_ with no proprietary APIs or hacks, can do.

It's also a fantastic offline citizen--even though nearly every interaction
in the app requires data from Foursquare's API. But Foursquare isn't _just_
about checking in to a place when you're online.

For instance: when I'm travelling, I'll often check to see what's nearby
using Foursquare when I have wifi (in a hotel room or a cafe), then head out
without an internet connection. Using the native Foursquare clients, I'm left
without the ability to see what's nearby once I'm offline. Not so with
_Around_: if I'm offline, it just uses the most recently cached data.

It also only makes requests to Foursquare's API on the first
request for something like a venue. Once any checkin, tip, user, or venue has
been loaded, we cache that data using [localForage](http://mozilla.github.io/localForage)
and display the cached data to the user **no matter what**. Even if the cached
data is expired, we'll show it while we fetch new, updated data.
All of this caching (and some pre-fetching) allows you to explore a
neighbourhood even after you've gone offline, provided you're had a look around
at some point beforehand.

## Cache All the Things!

Thanks to the
[powerful offline storage](/2014/02/12/localforage-offline-storage-improved/) afforded to
modern web apps, we can store a tonne of information in our apps, including
local versions of all of our models. This allows us to recreate an entire
screen's worth of data with the data cached on our device.

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

## Keep it Simple

The code that powers the caching in _Around_ is wildly simple:

{% highlight coffeescript %}
# Get a venue (or venues) by its ID. Will make a request to the Foursquare
# API if the user is not available in the local datastore.
get: (id, forceUpdate = false) ->
  d = $.Deferred()

  results = @where {id: id}

  # We store cached models and have a simple `isOutdated()` method that checks
  # the last time we got fresh data from the API.
  unless !results.length or results[0].isOutdated() or forceUpdate
    d.resolve(results[0])
    return d.promise()

  # Get information about this venue.
  API.request("venues/#{id}").done (data) =>

  # More code follows...
{% endhighlight %}

The above code is from a [Backbone](http://backbonejs.org/) collection, but the
same concept would apply in any framework. All data in _Around_ is cached using
a [custom offline sync powered by localForage](https://github.com/mozilla/localForage-backbone).

## The Takeaway

I'm not advocating tossing cache invalidation aside, but I am advocating for
fewer network requests--even for apps like a Foursquare client that interact
with a remote service. Latency on mobile networks are high and speeds aren't
LTE everywhere. Mozilla is looking to deploy a $25 smartphone which will only
support EDGE networking, so it's important to conserve resources for the next
group of smartphone users, who certainly won't be on the same kind of network
as those in San Francisco or Berlin.

So what can you do? Start with these suggestions:

* Whenever you request data from an API, cache it.
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
