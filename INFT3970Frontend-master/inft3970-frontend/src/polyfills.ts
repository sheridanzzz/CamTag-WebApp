/*
 * This file includes polyfills needed by Angular and is loaded before the app.
 * You can add your own extra polyfills to this file.
 *
 * This file is divided into 2 sections:
 *   1. Browser polyfills. These are applied before loading ZoneJS and are sorted by browsers.
 *   2. Application imports. Files imported after ZoneJS that should be loaded before your main file.
 *
 * The current setup is for so-called "evergreen" browsers; the last versions of browsers that auto-
 * matically update themselves. This includes Safari >= 10, Chrome >= 55 (including Opera), Edge >= 13
 * on desktop, and iOS 10 and Chrome on mobile.
 *
 * Learn more in https://angular.io/docs/ts/latest/guide/browser-support.html
 */

/*****************************************************************************************************
 ***************************************** BROWSER POLYFILLS *****************************************
 *****************************************************************************************************/

/* Used for reflect-metadata in JIT. If you use AOT (and only Angular decorators), you can remove. */
import 'core-js/es7/reflect';

/*
 * By default, zone.js will patch all possible macroTask and DomEvents.
 * The user can disable parts of macroTask/DomEvents patch by setting following flags:
 */

// (window as any).__Zone_disable_requestAnimationFrame = true; // disable patch requestAnimationFrame
// (window as any).__Zone_disable_on_property = true; // disable patch onProperty such as onclick
// (window as any).__zone_symbol__BLACK_LISTED_EVENTS = ['scroll', 'mousemove']; // disable patch specified eventNames

/*
 * In IE/Edge developer tools, the addEventListener will also be wrapped by zone.js
 * With the following flag, it will bypass `zone.js` patch for IE/Edge.
 */

// (window as any).__Zone_enable_cross_context_check = true;

/* Zone JS is required by default for Angular itself. */
import 'zone.js/dist/zone'; // Included with Angular CLI.

/*****************************************************************************************************
 **************************************** APPLICATION IMPORTS ****************************************
 *****************************************************************************************************/