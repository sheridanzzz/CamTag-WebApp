/*
This class/component/service/module is a part of the INFT3970 major project for TEAM6 (2018).
Team members: David Low, Jonathan Williams, Mathew Herbert, Sheridan Gomes, Harry Pallett, Dylan Levin.

Description: The settings map component allows the player to select a map area to use when playing game modes such as Battle Royale.
*/

import { Component, OnInit, Output, EventEmitter } from '@angular/core';

import OlMap from 'ol/Map';
import OlXYZ from 'ol/source/XYZ';
import OlTileLayer from 'ol/layer/Tile';
import VectorLayer from 'ol/layer/Vector';
import OlView from 'ol/View';
import Feature from 'ol/Feature';
import VectorSource from 'ol/source/Vector';
import Point from 'ol/geom/Point';
import Circle from 'ol/geom/Circle';
import { Circle as CircleStyle, Fill, Stroke, Style } from 'ol/Style';
import { fromLonLat, toLonLat } from 'ol/proj';
import { ErrorService } from 'src/app/core/error.service';
import { LocationService } from 'src/app/core/location.service';
import { StorageService } from 'src/app/core/storage.service';

@Component({
    selector: 'settings-map-page',
    templateUrl: './settings-map.component.html',
    styleUrls: ['./settings-map.component.css']
})
export class SettingsMapComponent implements OnInit {
    @Output() coordinates: EventEmitter<any> = new EventEmitter<any>();
    @Output() close: EventEmitter<any> = new EventEmitter<any>();
    map: OlMap;
    source: OlXYZ;
    layer: OlTileLayer;
    view: OlView;
    creatingArea = false;
    validArea = false;
    centrePoint = {
        latitude: 0,
        longitude: 0
    };
    radius = 0;

    constructor(private errorService: ErrorService, private location: LocationService, private storage: StorageService) { }

    ngOnInit() {
        const presetCoords = this.storage.getMemoryStorage('BRMapCoords');
        this.location.getLocation().then((position: any) => {
            // Set up the map tile source
            this.source = new OlXYZ({
                url: 'https://tile.osm.org/{z}/{x}/{y}.png'
            });
            this.layer = new OlTileLayer({
                source: this.source
            });
            var source = new VectorSource({ wrapX: false });
            var vector = new VectorLayer({
                source: source
            });

            // If the player has selected a location before, and is going back to the map, pre-load the last selection, otherwise just show a blank map.
            if (presetCoords != null) {
                var positionFeature = new Feature();
                // Set styling
                positionFeature.setStyle(new Style({
                    image: new CircleStyle({
                        radius: 6,
                        fill: new Fill({
                            color: '#3399CC'
                        }),
                        stroke: new Stroke({
                            color: '#fff',
                            width: 2
                        })
                    })
                }));
                // Get coordinates
                this.centrePoint.latitude = presetCoords.lat;
                this.centrePoint.longitude = presetCoords.long;
                this.radius = presetCoords.radius;
                const coordinates = [this.centrePoint.longitude, this.centrePoint.latitude];
                // Add the centre point
                positionFeature.setGeometry(new Point(fromLonLat(coordinates)));
                source.addFeature(positionFeature);
                // Add the radius circle around it
                var radiusFeature = new Feature(new Circle(fromLonLat([this.centrePoint.longitude, this.centrePoint.latitude]), this.radius));
                source.addFeature(radiusFeature);
                // Set up the default view to centre on the selection
                this.view = new OlView({
                    center: fromLonLat([this.centrePoint.longitude, this.centrePoint.latitude]),
                    zoom: 13
                });
            } else {
                // Set up the default view to centre on the player's location
                this.view = new OlView({
                    center: fromLonLat([position.coords.longitude, position.coords.latitude]),
                    zoom: 13
                });
            }


            // Create a new map, with EPSG:4326 projection.
            this.map = new OlMap({
                target: 'map',
                projection: 'EPSG:4326',
                layers: [this.layer, vector],
                view: this.view
            });

            // Handles when the player wants to select a location and area for the game. First click sets the centre point. Second
            // click sets the outer perimeter.
            this.map.on('click', (res) => {
                this.storage.removeMemoryStorage('BRMapCoords');
                // console.log('Res:', res);
                var coordinates = toLonLat([res.coordinate[0], res.coordinate[1]]);
                // console.log('Coordinates:', coordinates);
                this.validArea = false;

                //If it is the first click, set up the styling and add a point where the player clicks. Store this as the centre.
                if (!this.creatingArea) {
                    source.clear();
                    var positionFeature = new Feature();
                    positionFeature.setStyle(new Style({
                        image: new CircleStyle({
                            radius: 6,
                            fill: new Fill({
                                color: '#3399CC'
                            }),
                            stroke: new Stroke({
                                color: '#fff',
                                width: 2
                            })
                        })
                    }));
                    positionFeature.setGeometry(new Point(fromLonLat(coordinates)));
                    source.addFeature(positionFeature);
                    source.refresh({ force: true });
                    this.centrePoint.latitude = coordinates[1];
                    this.centrePoint.longitude = coordinates[0];
                    console.log(this.centrePoint);

                    this.creatingArea = true;
                } else { // If the player has already selected a centre, then find the distance to where the clicked, and set it as the radius.
                    console.log(this.centrePoint.latitude, this.centrePoint.longitude, coordinates[1], coordinates[0]);
                    this.radius = Math.round(this.distance(this.centrePoint.latitude, this.centrePoint.longitude, coordinates[1], coordinates[0], 'K') * 1000);
                    console.log(this.radius);

                    var radiusFeature = new Feature(new Circle(fromLonLat([this.centrePoint.longitude, this.centrePoint.latitude]), this.radius));
                    source.addFeature(radiusFeature);
                    source.refresh({ force: true });
                    this.validArea = true;
                    this.creatingArea = false;
                }
            });
        }).catch(() => {
            this.errorService.throwError('Required Permissions', 'You must enable location to play this game. The location is only tracked and recorded when you take a photo.');
        });
    }

    // Calculates the distance between two coordinates
    distance(lat1, lon1, lat2, lon2, unit) {
        var radlat1 = Math.PI * lat1 / 180
        var radlat2 = Math.PI * lat2 / 180
        var theta = lon1 - lon2
        var radtheta = Math.PI * theta / 180
        var dist = Math.sin(radlat1) * Math.sin(radlat2) + Math.cos(radlat1) * Math.cos(radlat2) * Math.cos(radtheta);
        if (dist > 1) {
            dist = 1;
        }
        dist = Math.acos(dist)
        dist = dist * 180 / Math.PI
        dist = dist * 60 * 1.1515
        if (unit == "K") { dist = dist * 1.609344 }
        if (unit == "N") { dist = dist * 0.8684 }
        return dist
    }

    emitClose() {
        this.close.emit();
    }

    emitCoords() {
        console.log(this.validArea);
        if (this.validArea) {
            this.storage.setMemoryStorage('BRMapCoords', { lat: this.centrePoint.latitude, long: this.centrePoint.longitude, radius: this.radius });
            this.coordinates.emit();
        }
    }
}