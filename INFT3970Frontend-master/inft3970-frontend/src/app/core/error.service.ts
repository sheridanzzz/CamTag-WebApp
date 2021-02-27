/*
This class/component/service/module is a part of the INFT3970 major project for TEAM6 (2018).
Team members: David Low, Jonathan Williams, Mathew Herbert, Sheridan Gomes, Harry Pallett, Dylan Levin.

Description: The error service provides a global way for the app to be able to throw an error if needed. If the throwError method
is called, it will trigger the app to redirect to the error page and display the message.
*/

import { Injectable } from '@angular/core';
import { Router } from '@angular/router';

@Injectable()
export class ErrorService {
    public error = null;
    constructor(private router: Router) { }

    throwError(errorTitle, errorMessage) {
        this.error = { errorTitle: errorTitle, errorMessage: errorMessage }
        this.router.navigateByUrl('error');
    }
}