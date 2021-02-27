/*
This class/component/service/module is a part of the INFT3970 major project for TEAM6 (2018).
Team members: David Low, Jonathan Williams, Mathew Herbert, Sheridan Gomes, Harry Pallett, Dylan Levin.

Description: The Selfie component handles taking a selfie when either creating or joining a game.
*/

import { Component, Input, Output, EventEmitter, ViewChild, OnInit } from '@angular/core';
import { ErrorService } from 'src/app/core/error.service';

@Component({
    selector: 'selfie-page',
    templateUrl: './selfie.component.html',
    styleUrls: ['./selfie.component.css']
})
export class SelfieComponent implements OnInit {
    @Input() imgURL: boolean;
    @Output() imgURLChange: EventEmitter<string> = new EventEmitter<string>();
    @Output() acceptSelfie: EventEmitter<string> = new EventEmitter<string>();
    @Output() goBack: EventEmitter<any> = new EventEmitter<any>();
    @ViewChild('hardwareVideo') hardwareVideo: any;
    
    video: any;
    localStream;
    pictureTaken = false;
    isStreaming = false;
    captureConstraints = { width: 512, height: 512 }

    constructor(private errorService: ErrorService) { }

    ngOnInit() {
        this.initialiseVideo();
    }

    back() {
        this.goBack.emit();
    }

    // Sets up the video stream through WebRTC
    initialiseVideo() {
        this.video = this.hardwareVideo.nativeElement;
        this.video.onplaying = () => {
            this.isStreaming = true;
            console.log('Video is now streaming', this.isStreaming);
        }
        navigator.mediaDevices.getUserMedia({ video: { facingMode: { exact: 'user' } } }).then((stream) => {
            this.video.srcObject = stream;
            this.video.play();
        }).catch((error) => {
            //Normally send the player to the error screen with the message
            console.log('Error getting device:', error);
            //For testing, try without the constraints
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
    }

    accept() {
        if (this.pictureTaken) {
            this.acceptSelfie.emit('');
        }
    }

    // Takes a picture from the current point in time of the video stream, and returns it as a JPG data url.
    takePicture() {
        const canvas = <HTMLCanvasElement>document.getElementById('camera-capture');
        // Create canvas
        const context = canvas.getContext('2d');
        if (this.captureConstraints.width && this.captureConstraints.height) {
            // set canvas props
            console.log(this.video);
            let cropLeft = 0;
            let cropTop = 0;
            if (this.video.videoHeight / this.video.videoWidth >= 1) {
                cropTop = Math.abs((this.video.videoHeight - this.video.videoWidth) / 2);
            } else {
                cropLeft = Math.abs((this.video.videoHeight - this.video.videoWidth) / 2);
            }
            console.log(cropLeft, cropTop);
            // cropLeft = 0;
            canvas.width = this.captureConstraints.width;
            canvas.height = this.captureConstraints.height;
            // Draw an image of the video on the canvas
            context.drawImage(this.video, cropLeft, cropTop, this.video.videoWidth - (cropLeft * 2), this.video.videoHeight - (cropTop * 2), 0, 0, this.captureConstraints.width, this.captureConstraints.height);
            this.imgURLChange.emit(canvas.toDataURL('image/jpeg'));
            this.pictureTaken = true;
        }
    }

    takeAgain() {
        this.pictureTaken = false;
    }
}