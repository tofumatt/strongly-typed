---
layout: post
title: "Higher Fidelity"
description: "The beginnings of a better way to build web apps."
tags: [open source, open web apps]
image:
  feature: on-air.jpg
  credit: Jody Sticca
  creditlink: https://secure.flickr.com/photos/jody_art/8461656636
share: true
---

I've been struggling with web frameworks, best practices, and tools for awhile. I fought with light frameworks like Backbone--they didn't handle data-binding tightly enough for me, forcing me to manage too much state. And frameworks like Angular or Ember struck me as too opaque; the learning curve was high. What's worse is that none of these frameworks had an "offline first" feel to them. Most of the docs talk about REST servers and synchronizing data back and forth. After realizing none suited my needs I rebuilt Mozilla's ailing [HTML5 Podcasts app] using Brick, Ember, Grunt, Yeoman, and a bit of extras on top. I feel like I've struck on a good way to write HTML5 apps for Firefox OS, so I'd like to talk about how I rebuild Podcasts for Firefox with [Mozilla's Rec Room][].

I started work on an [HTML5 podcast app][] [well over a year ago][], but I wasn't pleased with how it turned out. I'd been writing [reference apps][] for Mozilla for the past year or so and I was frustrated with HTML5 apps compared to my experience using Rails, Django, and even Xcode.

<!-- Writing for the web can be a bit daunting because of the paradox of choice. I don't think choice is bad and I'm not here to sway anyone away from a process that already works for them. But in learning frameworks like Backbone or Ember, as well as tools like Grunt or Yeoman, I found little more than piecemeal solutions. I hadn't found anything like Rails, which held my hand through pretty much any part of the development process that I shouldn't have to think about.

I think I've pieced together a set of tools that makes writing non-trivial, offline-first web apps easier and more like I remember writing Rails apps.

First off I'd like to walk through the differences between my old app and new one, but afterward I'd like to talk about the tooling I've extracted from building Podcasts that I hope other developers can take advantage of to write their own Open Web Apps for Firefox OS. -->

[HTML5 Podcasts app]: https://github.com/mozilla/high-fidelity/
[reference apps]: https://developer.mozilla.org/en-US/Apps/Reference_apps
[well over a year ago]: https://github.com/mozilla/high-fidelity/commit/6f023aa399b3d7b773d0f41c182d9f7b328a6184

## Starting with a Scaffold

[Yeoman] is pretty much tailor-made for what I was looking to do: have awesome scaffolds for common patterns in my web apps. I started with an Ember app scaffold, but built on it so that there's now an entire [generator-recroom][] repository you can use to quickly scaffold Firefox OS apps with a sane folder structure, build system, test harness, and Firefox OS-specific manifests.

In the old version of Podcasts I just created all my Backbone files from scratch and set up a confusing path of `require()` calls to meld them all together. The new version of Podcasts has two sets of scaffolds: a `model` scaffold that I used to create the `Podcast` and `Episode` controllers, models, routes, and templates. The other was the `page` scaffold, which adds a "page" to our single page web app to display content less bound to a CRUD setup. Every file in the new app was created using the `recroom scaffold` command, and the `recroom run` and `recroom build` commands automatically include these new files as they're created.

It works well and I don't have to clumsily remember which files I need to create to make a new model or page.

[generator-recroom]: https://github.com/mozilla/generator-recroom
[Yeoman]: http://yeoman.io/

## Build Steps

The old Podcasts app used a [(rather awful) Makefile][Makefile]. It wasn't very useful, and I don't think it ran on Windows without some *serious* effort. The new build system uses Node so it runs comfortably on Windows, Mac, and Linux. Tasks are handled by Grunt for now, though I'm considering looking at Gulp in the future. Really important commands are proxied via the `recroom` binary, also written in Node, so you don't have to worry about the underlying system if you don't need to modify build steps. `recroom new My-App` creates a new app; `recroom serve` serves up your new app, and `recroom scaffold model Podcast` creates a new model for you. Of course, if you know Grunt you can call specific tasks as you wish. Rec Room doesn't hide anything from you, but it will abstract things away for new users.

[Makefile]: https://github.com/mozilla/high-fidelity/blob/f73b8b4bde0753512a2c905e66c8a84fafb56e5e/Makefile

## UI Improvements

Thanks to [Brick][], the UI of the Podcasts app is much improved. I didn't really have to think about much of the UI; Brick's `appbar` and `tabbar` components did most of the heavy lifting for me.

#### Old:

<img src="{{ site.url }}/images/podcasts-before.png" alt="Earlier version of Podcasts app" class="photograph">
<img src="{{ site.url }}/images/podcasts-before-2.png" alt="Earlier version of Podcasts app" class="photograph">

#### New:

<img src="{{ site.url }}/images/podcasts-after.png" alt="Earlier version of Podcasts app" class="photograph">
<img src="{{ site.url }}/images/podcasts-after-2.png" alt="Earlier version of Podcasts app" class="photograph">

I tried to get away from using the Gaia UI, which I think is bad form anyway as it changes from version-to-version and doesn't feel as clean or condensed in earlier version as the default Brick styles.

[Brick]: https://mozbrick.github.io/

## Heavy Lifting

The Backbone version of Podcasts required a *lot* more manual intervention and work than the new Ember version. Ember handles data binding, model persistence, and templating much more magically than Backbone, but it's not opaque or hard to override. Check out the difference in code from the Backbone Podcast Controller and the Ember Podcast Controller:

{% highlight js %}
// There's actually extra bits of `define()` in this code I've stripped out.
var PodcastView = Backbone.View.extend({
    className: 'podcast',
    el: '#podcast-details',
    $el: $('#podcast-details'),
    model: Podcast,
    template: PodcastDetailsTemplate,

    events: {
        'click .destroy': 'destroyPrompt'
    },

    initialize: function() {
        var self = this;

        _(this).bindAll('destroyPrompt', 'render');

        this.model.on('destroy', function() {
            self.remove();
        });

        this.render();
    },

    render: function() {
        var html = this.template({
            podcast: this.model
        });

        $('#podcasts-tab-container').append(html);

        this.model.episodes().forEach(function(episode) {
            var view = new EpisodeView({
                model: episode
            });
        });

        this.el = '#podcast-details';
        this.$el = $(this.el);

        this.$el.addClass('active');
    },

    destroyPrompt: function(event) {
        var self = this;

        var dialog = new DialogViews.DeletePodcast({
            confirm: function() {
                // Destroying the model will trigger both the detail and
                // cover views own `remove()` methods.
                self.model.destroy();

                // Go back to the list of podcasts, as we've just deleted
                // this one!
                window.router.navigate('/podcasts', {trigger: true});
            },
            templateData: _.defaults({
                description: null
            }, {
                imageURL: self.model.coverImage,
                podcast: self.model
            })
        });
    }
});
{% endhighlight %}

And here's the Ember version that does the same thing:

{% highlight js %}
// This is the entire file.
HighFidelity.PodcastController = Ember.ObjectController.extend({
    actions: {
        delete: function() {
            this.get('model').destroyRecord();

            this.transitionToRoute('podcasts');
        },

        update: function() {
            this.get('model').update();
        }
    }
});
{% endhighlight %}

I don't have to worry about re-rendering the template on certain events, and Ember's data-binding automatically re-renders only the part of my templates that change, instead of re-rendering an entire chunk of the DOM every time a tiny variable changes. This is much less prone to error and also noticeably faster.

## Show me the Numbers

Using [@digiarald][]'s awesome [firewatch][] tool, I found that new Rec Room apps used on average 2x-2.5x the memory of Gaia apps (apps like Clock used about 9MB on my Flame device -- Podcasts used between 20-30MB). For a point of reference, the highly optimized Firefox Marketplace app on my Flame device uses the same amount of memory (about 18-25MB). I feel like these numbers speak well to the kind of performance you can expect with this Ember set up -- and I haven't even tried to optimize anything yet.

[@digiarald]: https://twitter.com/digitarald
[firewatch]: https://www.npmjs.org/package/firewatch

## Podcasts on Firefox OS

The [new Podcasts app is up as a beta in the Firefox Marketplace][Podcasts Marketplace Listing]. Go try it out and see what a Rec Room app feels like. If you want to experiment with the same tools I used to build Podcasts, check out the [Rec Room project][Rec Room]. The project is evolving and the docs are still coming, but the aim is to combine Ember, Node task and test runners, and some great docs to allow to you build great web apps easily and with less worrying about the mundane details.

[Podcasts Marketplace Listing]: https://marketplace.firefox.com/app/podcasts
[Rec Room]: https://github.com/mozilla/recroom/
