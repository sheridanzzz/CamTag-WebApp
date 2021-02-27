/*
This component was written for the INFT3970 major project for TEAM6 (2018).
Team members: David Low, Jonathan Williams, Mathew Herbert, Sheridan Gomes, Harry Pallett, Dylan Levin.

Description: This component displays the error page when a major issue has occurred.
*/

import { Component, OnInit } from '@angular/core';
import { ErrorService } from '../error.service';

@Component({
    selector: 'error-page',
    templateUrl: './error.component.html',
    styleUrls: ['./error.component.css']
})

export class ErrorComponent implements OnInit {
    errorTitle = '';
    errorMessage = '';

    constructor(private errorService: ErrorService) { }

    ngOnInit() {
        if (this.errorService.error != null) {
            this.errorTitle = this.errorService.error.errorTitle;
            this.errorMessage = this.errorService.error.errorMessage;
            this.errorService.error = null;
        } else {
            this.errorTitle = "ARE YOU LOST?";
            this.errorMessage = "I'm not sure why you want to visit the error page, there aren't any errors currently.";
        }
    }
}