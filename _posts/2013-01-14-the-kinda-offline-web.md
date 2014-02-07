---
layout: post
title: "The Kinda Offline Web"
description: "Offline technology is mature enough to use, but do most web developers know how?"
tags: [code, development, offline]
image:
  feature: storage-shed-hdr.jpg
  credit: katsrcool
  creditlink: http://www.flickr.com/photos/40775084@N05/9475526152/
share: true  
---

Offline technology is mature enough to use, but do most web developers know how?

The phrase "web app" has traditionally meant something like [Basecamp](http://basecamp.com/) -- an app accessed at a URL. But many traditional web apps are online, slower that locally-hosted apps with no latency, and bound to a browser. At Mozilla, we're trying to change all of this with FirefoxOS and Open Web Apps. One of the biggest changes to what we call a web app can be encompassed in one word: **offline**.

A few months ago I started work on [Face Value](http://facevalueapp.com/), an open web app that deals with a currency's denominations in a saner way for most travellers. I knew the app would need to work offline; most users would use the app on their phone, often in a foreign country without a data plan.

I know a lot about the localStorage API and even some things about Appcache, but I hadn't ever made a truly offline web app before Face Value. What's worse, I didn't know about some of the really common gotchas one runs into when going from building web apps that rely on a net connection to ones that work offline without issues. My first few attempts were quite buggy, but in the end I have something that I'm quite proud with and trust to take with me--even when I'm without precious, precious data on my phone.

## Ingredients

So just what does one need in order to make a web app function offline? Turns out the list isn't too long:

* **Appcache** is basically mandatory
* **localStorage** allows you to store user data on the client
* **IndexedDB** lets you store huge files, but we'll save talking about it for an upcoming post

"Wait, that's it?" you might be thinking. It's not a lot of tech that goes into writing offline apps. But the amount of edge cases, misconceptions, and gotchas are much bigger.

## localStorage

Storing user data locally, it turns out, is actually the most straightforward task of the bunch. localStorage's API is obscenely simple: it's a key-value storage system accessible like any other JavaScript object; `window.localStorage.myName = 'Matt'` will set the key `myName` and `window.localStorage.myName` will predictably return `'Matt'`.

The two biggest gotchas to localStorage are:

### i. localStorage offers a finite amount of storage.

It's safe to assume you have at least `2.5MB` to work with, which should be more than enough to store app data, serialized Backbone objects, and user settings. Browsers vary in the size they give out for localStorage and how they deal with it, but in Chrome, Firefox, and Safari you'll have at least `5MB` to work with. So don't try to store large binary files or HUGE chunks of data in localStorage. For most apps though, this is more than enough space.

### ii. localStorage should've be called "stringStorage".

localStorage only stores strings. If you attempt to save anything that isn't a string to localStorage: it won't work and will *fail silently*. In order to save other data to localStorage you'll need to convert it to data that can be represented inside a string. Effectively, this means running [`JSON.stringify()`](https://developer.mozilla.org/en-US/docs/JavaScript/Reference/Global_Objects/JSON/stringify) on anything you save to localStorage (conversely, when getting data from localStorage, just run [`JSON.parse()`](https://developer.mozilla.org/en-US/docs/JavaScript/Reference/Global_Objects/JSON/parse) on any data you've saved this way).

Of course, if you're storing complicated data (like Backbone models), you'll want to look into something like the [localStorage sync backend Face Value](https://github.com/tofumatt/face-value/blob/971910ac583538df71910958817afaf286af4c6b/www/js/lib/backbone.localstorage.js) uses.

The main thing to remember is that you'll likely want to abstract getting/setting data in localStorage to handle the JSON conversion; [here's the code that does it in Face Value](https://github.com/tofumatt/face-value/blob/971910ac583538df71910958817afaf286af4c6b/www/js/app.js#L90-124).

## Appcache (is a Four Letter Word)

Appcache is the technology that allows you to explicitly instruct the browser which assets on your (or someone else's) server to cache locally for your app to request. It's powered by a very simple "appcache manifest", [which looks like this](https://github.com/tofumatt/face-value/blob/971910ac583538df71910958817afaf286af4c6b/www/manifest.appcache). It powers [facevalueapp.com](http://facevalueapp.com/) and ensures it works even once your computer or phone is offline. It's an awesome idea, but it's got some rough edges that you really need to be aware of before attempting to leverage it. I think that had someone warned me about these pitfalls before I started building Face Value I'd have been much better off (and spent less time cursing Appcache).

### It's Oh So Quiet

If you're used to using Firebug or Chrome/Firefox/Safari Developer Tools, you'll notice there still aren't amazing tools for inspecting stuff in Appcache. Actually, Appcache still doesn't have a very mature API and its support in browsers is still early. Hopefully this is made better in the future, but the two things you need to know are:

1. **Every file** in your Appcache Manifest **must be accessible** (no 404s).
2. If **a single file** in your manifest **isn't available your manifest isn't valid** and all cached data is invalidated.

This might seem harsh, but the trick is simply to remember to make sure all files in your manifest exist. In a future post I'll try to show you some events you can attach handlers to so you can check for Appcache errors. For now, just remember these rules.

### Reload!

It might seem unintuitive that the cached version of your page isn't used until after all files in the manifest are loaded and the URL is requested again. But because your Appcache isn't considered ready until *everything* in it is downloaded, this makes sense. Effectively, you need to do a [`window.location.reload()`](https://github.com/tofumatt/face-value/blob/971910ac583538df71910958817afaf286af4c6b/www/js/app.js#L40-48) once all resources are available. This is *especially* important if you want your app to work offline as soon as all files are cached; if you're marketing your app to iOS users who may well next access your app without data, they'll be treated to an error message claiming an Internet connection is required. Refreshing the page and forcing a load from Appcache fixes this problem.

Appcache manifests contain three sections: `CACHE`, `NETWORK`, and `FALLBACK`. Learn to love all three, and remember that because a single error will render your cache invalid, it's important not to put **any asset you don't directly control and serve** in your `CACHE` section. For instance: you're using [Google Web Fonts](http://www.google.com/webfonts) and want to cache your font. Fair enough, but because you don't control that asset it's worth placing it in the `FALLBACK` section where you can specify a different, local resource for it. Alternatively, you can pull in external resources (like content from a CDN) and put it in the `CACHE` section.

Just be careful about including foreign assets in your Appcache manifest -- you're effectively handing control of your cache validity to someone else then.

## Conditional Network Access

It's a common scenario to have an app that functions perfectly offline, but does make occasional network requests to do things like update data. Face Value is an excellent example of this: all currency and denomination is stored offline, but currency worth (accessed via Yahoo's Finance API) and currency/denomination data (accessed via Face Value's server) are updated once a day. More accurately, if it's been more than twenty four hours since you last opened the app, Face Value makes a network request to update its dataset before firing a callback that launches the app. Once the data is loaded, Face Value continues loading as normal; if it's been less than twenty four hours since you last updated, the page is immediately rendered without any network requests.

Unfortunately, in earlier versions of the app, I didn't anticipate this network request failing because I usually tested the app's offline capability immediately after I launched a fresh version of the app, meaning it was mere minutes since I last obtained this currency data. So my app worked fine in terms of localStorage and Appcache, but that network request failing just wasn't something I encountered in my manual testing!

## The Kinda Offline Web

It's important to think that any network request can fail (even on first load) when building offline web apps. My bug with conditional network access was [easily fixed](https://github.com/tofumatt/face-value/blob/971910ac583538df71910958817afaf286af4c6b/www/js/app.js#L68-79), but it's not the kind of thing web developers typically think of; even when we think offline, we're thinking a client-side game or token web app that never needs network access again.

The reality is that many apps need network access *some of the time*, but you have to be prepared for the reality of mobile apps: when you need network access it, you might not have it.

----

These were the particular gotchas I experienced during my time getting Face Value to work offline.

I'm currently working on a [podcasts app](https://github.com/mozilla/high-fidelity) for FirefoxOS and Firefox Desktop that stores large blobs of binary data. Because of Appcache's fragile nature and localStorage's limited storage, I used IndexedDB to store podcast files. I'll talk about my experiences with IndexedDB (and the wrapper around its API I'm working on) in an upcoming post.
