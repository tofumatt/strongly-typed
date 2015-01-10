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

Sometimes it takes a long time and a few steps back to realize the way you've been doing things isn't quite right. As a developer sometimes I'm guilty of working around problems rather than fixing them directly (even if I provide those solutions to others as well). I realized late last year that the way I was building web apps on at Mozilla wasn't _that_ great. Things were cobbled together and solutions weren't end-to-end. It involved guess work and a heck of a lot of web searches just to do what should be obvious. It **worked**, but it wasn't _optimal_. So the solution was simple: take my experience writing [reference apps][] at Mozilla and find a better way to write web apps.

What came out of this experiment to find a better way to write web apps is [Mozilla's Rec Room][], a set of docs, packages, and tools, combined to help novice and expert developers write client-side, offline-first web apps. It even includes some features that targe Firefox OS.

Much of Rec Room came from a recent rewrite of the [HTML5 podcast app][]. I started working on this app [well over a year ago][], but it was a bit of a fragile app back then; a _lot_ of global state and a lot of by-hand data-binding. I liked the look Angular and Ember for app development, but neither felt like they prioritized "offline first". Most of the docs talk about REST servers and synchronizing data back and forth. After realizing nothing _quite_ suited my needs: I rebuilt Mozilla's ailing HTML5 Podcasts app using Brick, Ember, Grunt, Yeoman, and a bit of our own extras on top. I tried to take the best from that system and extract it into a set of tools and documentation that anyone can use.

[HTML5 Podcasts app]: https://github.com/mozilla/high-fidelity/
[Mozilla's Rec Room]: https://github.com/mozilla/recroom
[reference apps]: https://developer.mozilla.org/en-US/Apps/Reference_apps
[well over a year ago]: https://github.com/mozilla/high-fidelity/commit/6f023aa399b3d7b773d0f41c182d9f7b328a6184

## Starting with a Scaffold

[Yeoman] is pretty much tailor-made for what I was looking to do: have awesome scaffolds for common patterns in my web apps. I started with an Ember app scaffold, but built on it so that there's now an entire [generator-recroom][] repository you can use to quickly scaffold Firefox OS apps with a sane folder structure, build system, test harness, and Firefox OS-specific manifests.

In the old version of Podcasts I just created all my Backbone files from scratch and set up a confusing set of `require()` calls to meld them all together. The new version of Podcasts has two sets of scaffolds: a `model` scaffold that I used to create the `Podcast` and `Episode` controllers, models, routes, and templates. The other was the `page` scaffold, which adds a "page" to our single page web app to display content less bound to a CRUD setup. Every file in the new app was created using the `recroom scaffold` command, and the `recroom run` and `recroom build` commands automatically include these new files as they're created.

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

```js
// There are actually extra bits of `define()` in this code I've stripped out.
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
```

And here's the Ember version that does the same thing:

```js
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
```

I don't have to worry about re-rendering the template on certain events, and Ember's data-binding automatically re-renders only the part of my templates that change, instead of re-rendering an entire chunk of the DOM every time a tiny variable changes. This is much less prone to error and also noticeably faster.

## Show me the Numbers

Using [@digiarald][]'s awesome [firewatch][] tool, I found that new Rec Room apps used on average only twice the memory of Gaia apps (apps like Clock used about 9MB on my Flame device -- Podcasts used between 20-30MB). Gaia apps are _extremely optimized_ for memory usage on Firefox OS; we did _zero_ Firefox OS-specific memory optimization and still got these pretty great numbers. For a point of reference, the highly optimized Firefox Marketplace app on my Flame device uses the same amount of memory (about 18-25MB). I feel like these numbers speak well to the kind of performance you can expect with this Ember set up -- and I haven't even tried to optimize anything yet.

[@digiarald]: https://twitter.com/digitarald
[firewatch]: https://www.npmjs.org/package/firewatch

## Podcasts on Firefox OS

The [new Podcasts app is up as a beta in the Firefox Marketplace][Podcasts Marketplace Listing]. Go try it out and see what a Rec Room app feels like. If you want to experiment with the same tools I used to build Podcasts, check out the [Rec Room project][Rec Room]. The project is evolving and the docs are still coming, but the aim is to combine Ember, Node task and test runners, and some great docs to allow to you build great web apps easily and with less worrying about the mundane details.

[Podcasts Marketplace Listing]: https://marketplace.firefox.com/app/podcasts
[Rec Room]: https://github.com/mozilla/recroom/

## Create your own Rec Room app

Rec Room has just recently been extracted from my experiences with Podcasts; it hasn't been tested by more than a handful of developers. That said: we'd love your help trying to build your own app for Firefox OS using these tools. They integrate well with tools you probably already know and use--like Node.js and Firefox's own Web IDE.

To get started, install Rec Room using Node.js:

```bash
npm install -g recroom
```

## Clock App

We'll create a simple clock app with (minimal) time zone support for our example. The app will let you have a clock and compare it with a few time zones.

The `recroom` binary is your entry point to all of the cool things Rec Room can do for you. First, create your app using `recroom new world-clock`. This creates the basic app structure. To see the basic app skeleton that Rec Room creates we can now enter that directory and run our app: `cd world-clock` and then type `recroom run`. The app will open in your default browser.

First, we'll add the current time to the main tab. Rec Room supports Ember's MVC app structure, but also offers simple "pages" for a controller without a 1:1 relationship to a model. We'll generate a new page that will show our actual clock:

```bash
recroom generate page Clock
```

We can edit its template by opening `app/templates/clock.hbs`. Let's change `clock.hbs` to include the variable that will output our local time:

```html
<h2>Local Time: {{localTime}}</h2>
```

That won't do much yet, so let's add that variable to our `ClockController`, in `app/scripts/controllers/clock_controller.js`:

```js
WorldClock.ClockController = Ember.ObjectController.extend({
    localTime: new Date().toLocaleTimeString()
});
```

You can see that any property inside the controller is accessible inside that controller's template. We define the `1ocalTime` property and it gets carried into our template context.

Now our clock app will show the current local time when we navigate to `http://localhost:9000/#clock`. Of course, it just shows the time it was when the controller was initialized; there is no live updating of the time. We should update the time every second inside the controller:

```js
WorldClock.ClockController = Ember.ObjectController.extend({
    init: function() {
        // Update the time.
        this.updateTime();

        // Run other controller setup.
        this._super();
    },

    updateTime: function() {
        var _this = this;

        // Update the time every second.
        setTimeout(function() {
            _this.set('localTime', new Date().toLocaleTimeString());
            _this.updateTime();
        }, 1000);
    },

    localTime: new Date().toLocaleTimeString()
});
```

Now we can go to our clock URL and see our clock automatically updates every second. This is thanks to Ember's data-binding between controllers and templates; if we change a value in a controller, model, or view that's wired up to a template, the template will automatically change that data for us.

## Adding Timezones

Next, we want to add a few timezones that the user can add to their own collection of timezones to compare against local time. This will help them schedule their meetings with friends in San Francisco, Buenos Aires, and London.

We can create a timezone model (and accompanying controllers/routes/templates) with the same `generate` command, but this time we'll generate a model:

```bash
recroom generate model Timezone
```

We want each timezone we're to include in our app to have a name and an offset value, so we should add them as model attributes. We use [Ember Data][] for this, inside `app/scripts/models/timezone_model.js`:

```js
WorldClock.Timezone = DS.Model.extend({
    name: DS.attr('string'),
    offset: DS.attr('number')
});
```

Next we'll want a list of all timezones to offer the user. For this we'll grab a copy of [Moment Timezone][]. It's an awesome JavaScript library for dealing with dates and times in JavaScript. We'll install it with [bower][]:

```bash
bower install moment-timezone --save
```

And then add it to our app inside `app/index.html`:

```html
<!-- build:js(app) scripts/components.js -->
[Other script tags]
<script src="bower_components/moment/moment.js"></script>
<script src="bower_components/moment-timezone/builds/moment-timezone-with-data-2010-2020.js"></script>
<!-- endbuild -->
```

Adding that tag will automatically add `moment-timezone-with-data-2010-2020.js` to our built app. We'll add a tab to the page that lets us edit our timezones, on a different screen than the clocks. To add a tab, we just need to open `app/templates/application.hbs` and add a tab. While we're there, we'll change the main tab from the useless `{{#linkTo 'index'}}` and point it to `{{#linkTo 'clock'}}`. The new `application.hbs` should look like this:

```html
<x-layout>
  <header>
    <x-appbar>
      <h1>{{t app.title}}</h1>
    </x-appbar>
  </header>
  <section>
    {{outlet}}
  </section>
  <footer>
    <x-tabbar>
      <x-tabbar-tab>
        {{#link-to 'clock'}}Clock{{/link-to}}
      </x-tabbar-tab>
      <x-tabbar-tab>
        {{#link-to 'timezones'}}Timezones{{/link-to}}
      </x-tabbar-tab>
    </x-tabbar>
  </footer>
</x-layout>
```

Side note: notice the root URL points to a useless welcome page? We probably want the default route to be our `ClockController`, so we can set the index route to redirect to it. Let's do that now, in `app/scripts/routes/application_route.js`:

```js
WorldClock.ApplicationRoute = Ember.Route.extend({
    redirect: function() {
        this.transitionTo('clock');
    }
});
```

## Interacting with Timezone models

We'll keep things simple for our example and allow users to select a timezone from a `<select>` tag and add it with a button. It will show up in their list of timezones, and they can delete it if they want from there. The clock tab will show all times. First, we'll add our timezone data from Moment.js into our `TimezonesController` in `app/scripts/controllers/timezones_controller.js`. We're also going to implement two actions: "add" and "remove". These will be used in our template:

```js
WorldClock.TimezonesController = Ember.ObjectController.extend({
    init: function() {
        var timezones = [];

        for (var i in moment.tz._zones) {
            timezones.push({
                name: moment.tz._zones[i].name,
                offset: moment.tz._zones[i].offset[0]
            });
        }

        this.set('timezones', timezones);

        this._super();
    },

    selectedTimezone: null,

    actions: {
        add: function() {
            var timezone = this.store.createRecord('timezone', {
                name: this.get('selectedTimezone').name,
                offset: this.get('selectedTimezone').offset
            });

            timezone.save();
        },

        remove: function(timezone) {
            timezone.destroyRecord();
        }
    }
});
```

So we create a list of _all_ available timezones with offsets. Then we add methods that allow us to add or remove timezones from our offline data store. Next we modify the timezones template in `app/templates/timezones.hbs` to use the actions and variables we created. All we need to utilize these variables is the Ember `SelectView` and the `{{action}}` helper to call our `add` and `remove` methods:

```html
<h2>Add Timezone</h2>

{{view Ember.Select content=timezones selection=selectedTimezone
       optionValuePath='content.offset' optionLabelPath='content.name'}}

<button {{action add}}>Add Timezone</button>

<h2>My Timezones</h2>

<ul>
  {{#each model}}
    <li>{{name}} <button {{action remove this}}>Delete</button></li>
  {{/each}}
</ul>
```

Now we have a Timezones tab that allows us to add and remove Timezones we want to track. This data persists between app refreshes. The last thing we need to do is show these times relative to our local time in our clock tab. To do this we need to load all the `Timezone` models in the `ClockRoute`. They're automatically loaded in the `TimezonesRoute`, but it's easy to add them in the `ClockRoute` (in `app/scripts/routes/clock_route.js`):

```js
WorldClock.ClockRoute = Ember.Route.extend({
    model: function() {
        return this.get('store').find('timezone');
    }
});
```

Because of the way our Ember app is wired up, we load all our models in the route and they are sent to the controller once the data store has asynchonously loaded all of the models. The request to `find('timezone')` actually returns a `Promise` object, but Ember's router handles the Promise resolving for us automatically so we don't have to manage callbacks or Promises ourselves.

Now we have access to all the user's Timezones in the `ClockController`, so we can make times in each timezone the user has requested and show them in a list. First we'll add each Timezone's current time to our `ClockController` in `app/scripts/controllers/clock_controller.js` using Moment.js:

```js
WorldClock.ClockController = Ember.ObjectController.extend({
    init: function() {
        // Update the time.
        this.updateTime();

        // Run other controller setup.
        this._super();
    },

    updateTime: function() {
        var _this = this;

        // Update the time every second.
        setTimeout(function() {
            _this.set('localTime', moment().format('h:mm:ss a'));

            _this.get('model').forEach(function(model) {
                model.set('time',
                          moment().tz(model.get('name')).format('h:mm:ss a'));
            });

            _this.updateTime();
        }, 1000);
    },

    localTime: moment().format('h:mm:ss a')
});
```

 Our final `app/templates/clock.hbs` should look like this:

```html
<h2>Local Time: {{localTime}}</h2>

{{#each model}}
  <h3>{{name}}: {{time}}</h3>
{{/each}}
```

And that's it! Now we have an offline app that shows us time zones in various places, saves the data offline, and updates every second without us having to do much work!

## See the app in action!

This entire sample app is available at [tofumatt.com/tous-le-temps](tofumatt.com/tous-le-temps) and the [source code is available on GitHub](https://github.com/tofumatt/tous-le-temps).

[bower]: http://bower.io/
[Ember Data]: https://github.com/emberjs/data
[Moment Timezone]: http://momentjs.com/timezone/
