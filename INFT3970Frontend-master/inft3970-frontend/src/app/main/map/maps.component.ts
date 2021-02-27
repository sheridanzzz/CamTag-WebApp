/*
This class/component/service/module is a part of the INFT3970 major project for TEAM6 (2018).
Team members: David Low, Jonathan Williams, Mathew Herbert, Sheridan Gomes, Harry Pallett, Dylan Levin.
*/

import { Component, OnInit, Output, EventEmitter } from '@angular/core';
import { ApiService } from 'src/app/core/api.service';

import OlMap from 'ol/Map';
import OlXYZ from 'ol/source/XYZ';
import OlTileLayer from 'ol/layer/Tile';
import VectorLayer from 'ol/layer/Vector';
import { defaults as defaultControls } from 'ol/control';
import OlView from 'ol/View';
import Feature from 'ol/Feature';
import VectorSource from 'ol/source/Vector';
import Point from 'ol/geom/Point';
import Circle from 'ol/geom/Circle';

import { Circle as CircleStyle, Fill, Stroke, Style, Icon } from 'ol/Style';
import { fromLonLat } from 'ol/proj';
import { ErrorService } from 'src/app/core/error.service';
import { LocationService } from 'src/app/core/location.service';

@Component({
    selector: 'maps-page',
    templateUrl: './maps.component.html',
    styleUrls: ['./maps.component.css']
})
export class MapsComponent implements OnInit {
    @Output() close: EventEmitter<any> = new EventEmitter<any>();
    map: OlMap;
    source: OlXYZ;
    layer: OlTileLayer;
    view: OlView;

    constructor(private api: ApiService, private errorService: ErrorService, private location: LocationService) { }

    ngOnInit() {
        this.location.getLocation().then((position: any) => {
            this.api.getLastKnownLocations().subscribe(res => {
                this.source = new OlXYZ({
                    url: 'https://tile.osm.org/{z}/{x}/{y}.png'
                });

                this.layer = new OlTileLayer({
                    source: this.source
                });

                this.view = new OlView({
                    center: fromLonLat([position.coords.longitude, position.coords.latitude]),
                    zoom: 13
                });

                var icons = [];
                res.data.photos.forEach(photo => {
                    var iconFeature = new Feature({
                        geometry: new Point(fromLonLat([photo.long, photo.lat]))
                    });
                    console.log(photo.lat, photo.long);
                    var iconStyle = new Style({
                        image: new Icon(/** @type {module:ol/style/Icon~Options} */({
                            anchor: [0.5, 46],
                            anchorXUnits: 'fraction',
                            anchorYUnits: 'pixels',
                            src: photo.takenByPlayer.extraSmallSelfie
                        }))
                    });

                    iconFeature.setStyle(iconStyle);
                    icons.push(iconFeature);
                });

                var iconSource = new VectorSource({
                    features: icons
                });

                var pinLayer = new VectorLayer({
                    source: iconSource
                });

                var radiusSource = new VectorSource();

                var radiusLayer = new VectorLayer({
                    source: radiusSource
                });

                var positionFeature = new Feature();
                positionFeature.setStyle(new Style({
                    image: new CircleStyle({
                        radius: 6,
                        fill: new Fill({
                            color: '#33CC99'
                        }),
                        stroke: new Stroke({
                            color: '#fff',
                            width: 2
                        })
                    })
                }));

                var playerCoordinates = fromLonLat([position.coords.longitude, position.coords.latitude]);
                positionFeature.setGeometry(playerCoordinates ?
                    new Point(playerCoordinates) : null);
                radiusSource.addFeature(positionFeature);

                if (res.data.radius > 0) {
                    var coordinates = fromLonLat([res.data.longitude, res.data.latitude]);
                    var radiusFeature = new Feature(new Circle(coordinates, res.data.radius));
                    radiusSource.addFeature(radiusFeature);
                }

                this.map = new OlMap({
                    target: 'map',
                    layers: [this.layer, pinLayer, radiusLayer],
                    view: this.view,
                    controls: defaultControls({
                        attributionOptions: {
                            collapsible: false
                        }
                    }),
                    projection: 'EPSG:4326'
                });

                this.map.on('click', (res) => {
                    console.log(res);
                });

            }, err => {
                console.log('Error:', err);
            });

        }).catch(() => {
            this.errorService.throwError('Required Permissions', 'You must enable location to play this game. The location is only tracked and recorded when you take a photo.');

        });
    }

    closeModal() {
        this.close.emit();
    }
}