/*
This class/component/service/module is a part of the INFT3970 major project for TEAM6 (2018).
Team members: David Low, Jonathan Williams, Mathew Herbert, Sheridan Gomes, Harry Pallett, Dylan Levin.

Description: The Main Component provides the primary screen used while playing the game. From here, the player may take a photo,
use the side menu to visit the scoreboard page or leave the game, view their notifications, and check out the map.
*/

import { Component, OnInit, OnDestroy, ViewChild } from '@angular/core';
import { Router } from '@angular/router';
import { Subscription } from 'rxjs';

import { ApiService } from './../core/api.service';
import { StorageService } from '../core/storage.service';
import { PushService } from '../core/push.service';
import { LocationService } from '../core/location.service';
import { ErrorService } from '../core/error.service';
import { MessageService } from '../core/message.service';

@Component({
    selector: 'main-page',
    templateUrl: './main.component.html',
    styleUrls: ['./main.component.css']
})
export class MainComponent implements OnInit, OnDestroy {
    @ViewChild('hardwareVideo') hardwareVideo: any;
    showNotificationModal = false;
    showMapModal = false;
    showTagModal = false;
    showMenuModal = false;
    video: any;
    localStream;

    ammoReplenishedSubscription: Subscription;
    notificationSubscription: Subscription;
    playerDisabledSub: Subscription;
    playerReenabledSub: Subscription;
    ammoCount: any;
    isDisabled = false;
    isStreaming = false;

    notificationCount = 0;
    captureConstraints = { width: 512, height: 512 }
    picture = '';
    view = '';

    constructor(private api: ApiService, private storage: StorageService, private pushService: PushService, private location: LocationService, private router: Router, private errorService: ErrorService, private messageService: MessageService) { }

    // On initialisation, the main component will check whether the player has been eliminated or disabled, set up the video feed, and
    // subscribe to the ammo, player disabled and notification push subjects, and load the player ammo count.
    ngOnInit() {
        // Handle players who have been eliminated.
        let playerStatus = this.storage.getItem('PlayerStatus');
        if (playerStatus == 'ELIMINATED') {
            this.router.navigateByUrl("/scoreboard");
        } else if (playerStatus == 'DISABLED') {
            this.isDisabled = true;
        } else {
            this.isDisabled = false;
        }

        this.ammoCount = "-";
        // Load the video stream to use to take photos
        this.video = this.hardwareVideo.nativeElement;
        this.video.onplaying = () => {
            this.isStreaming = true;
            console.log('Video is now streaming', this.isStreaming);
        }
        navigator.mediaDevices.getUserMedia({ video: { facingMode: { exact: 'environment' } } }).then((stream) => {
            this.video.srcObject = stream;
            this.video.play();
        }).catch((error) => {
            navigator.mediaDevices.getUserMedia({ video: true }).then((stream) => {
                this.video.srcObject = stream;
                this.video.play();
                console.log('Streaming video now');
            }).catch((error) => {
                console.log('Error getting video stream:', error);
                let message = {
                    header: '',
                    content: ''
                };
                switch (error.name) {
                    case 'NotAllowedError':
                        message.header = 'Required Permissions';
                        message.content = 'This game cannot be played unless you accept the permission to use the camera.';
                        break;
                    case 'NotReadableError':
                        message.header = 'Cannot Get Video';
                        message.content = 'Unable to claim the video camera. Please check whether any other apps are currently using it and close them if so.';
                        break;
                    case 'OverconstrainedError':
                    default:
                        message.header = 'Unsupported hardware';
                        message.content = 'Unfortunately this device cannot be used to play this game. Please ensure you have both a front and back camera, and have accepted the permissions.';
                        break;
                }
                this.errorService.throwError(message.header, message.content);
            });
        });

        this.ammoReplenishedSubscription = this.pushService.ammoReplenished.subscribe((res) => {
            this.getPlayerAmmoCount();
        });

        this.playerDisabledSub = this.pushService.playerDisabled.subscribe((res) => {
            this.isDisabled = true;
            this.ammoCount = "-";

        });

        this.playerReenabledSub = this.pushService.playerReenabled.subscribe((res) => {
            this.isDisabled = false;
            this.getPlayerAmmoCount();
        });

        // Set up notification subscription.
        this.notificationSubscription = this.pushService.notificationUpdate.subscribe(() => {
            this.api.getPlayerNotificationCount().subscribe(res => {
                console.log('NOTIFICATIONS:', res);
                this.notificationCount = res.data ? res.data : 0;
                console.log(this.notificationCount);
            }, error => {
                console.log('ERROR CALLBACK');
            });

        });

        this.getPlayerAmmoCount();
    }

    // Unsubscribes the subscriptions when finished to prevent memory leaks and odd issues on other pages.
    ngOnDestroy() {
        this.ammoReplenishedSubscription.unsubscribe();
        this.notificationSubscription.unsubscribe();
        this.playerDisabledSub.unsubscribe();
        this.playerReenabledSub.unsubscribe();
    }

    // Hides an active modal view.
    hideModal(event, id) {
        console.log('hide modal:', event, id);
        if (event != null && event.target.id == id) {
            switch (id) {
                case 'notificationModal':
                    this.showNotificationModal = false;
                    break;
                case 'mapModal':
                    this.showMapModal = false;
                    break;
                case 'cameraModal':
                    this.showTagModal = false;
                    break;
                case 'menuModal':
                    this.showMenuModal = false;
                    break;
            }
        }
    }

    // Gets the player ammo count.
    getPlayerAmmoCount() {
        if (!this.isDisabled) {
            this.api.getPlayerAmmoCount().subscribe(res => {
                this.ammoCount = res.data;
            });
        }
    }

    // Takes a picture from the current point in time of the video stream, records the location, then opens up the tag page.
    takePicture() {
        const canvas = <HTMLCanvasElement>document.getElementById('camera-capture');
        const context = canvas.getContext('2d');
        if (this.captureConstraints.width && this.captureConstraints.height) {
            // Crop a square image from the video feed.
            let cropLeft = 0;
            let cropTop = 0;
            if (this.video.videoHeight / this.video.videoWidth >= 1) {
                cropTop = Math.abs((this.video.videoHeight - this.video.videoWidth) / 2);
            } else {
                cropLeft = Math.abs((this.video.videoHeight - this.video.videoWidth) / 2);
            }
            console.log(cropLeft, cropTop);
            canvas.width = this.captureConstraints.width;
            canvas.height = this.captureConstraints.height;

            // Draw an image of the video on the canvas
            context.drawImage(this.video, cropLeft, cropTop, this.video.videoWidth - (cropLeft * 2), this.video.videoHeight - (cropTop * 2), 0, 0, this.captureConstraints.width, this.captureConstraints.height);
            this.picture = canvas.toDataURL('image/jpeg');

            // Get the current location
            this.location.getLocation().then((position: any) => {
                // Consume an ammo for the player
                this.api.consumeAmmo(position.coords.latitude, position.coords.longitude).subscribe(res => {
                    this.ammoCount = res.data.ammoCount;
                    // Set picture details and open the tag modal
                    this.storage.setMemoryStorage('picture', this.picture);
                    this.storage.setMemoryStorage('latitude', position.coords.latitude);
                    this.storage.setMemoryStorage('longitude', position.coords.longitude);
                    this.showTagModal = true;
                });
            }).catch(() => {
                this.errorService.throwError('Required Permissions', 'You must enable location to play this game. The location is only tracked and recorded when you take a photo.');

            });
        }
    }

    // Leaves the current game and retuns to the start screen
    leaveGame() {
        if (confirm("Are you sure you want to leave the game?")) {
            this.api.postLeaveGame().subscribe(res => {
                this.pushService.disconnect();
                this.storage.clearEverything();
                this.router.navigateByUrl('start');
            }, err => {
                console.log('Error:', err);
            });
        }
    }
}