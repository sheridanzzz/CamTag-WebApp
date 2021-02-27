/*
This class/component/service/module is a part of the INFT3970 major project for TEAM6 (2018).
Team members: David Low, Jonathan Williams, Mathew Herbert, Sheridan Gomes, Harry Pallett, Dylan Levin.
*/

import { Component, OnInit, Output, EventEmitter, OnDestroy } from '@angular/core';

import { ApiService } from '../../core/api.service';
import { PushService } from '../../core/push.service';

@Component({
    selector: 'notifications-page',
    templateUrl: './notifications.component.html',
    styleUrls: ['./notifications.component.css']
})
export class NotificationsComponent implements OnInit, OnDestroy {
    @Output() close: EventEmitter<any> = new EventEmitter<any>();
    loading = false;
    notifications = [];
    getAll = false;
    private notificationSubscription;

    constructor(private api: ApiService, private pushService: PushService) { }

    ngOnInit() {
        this.getNotifications();
        this.notificationSubscription = this.pushService.notificationUpdate.subscribe((res) => {
            if (res > 0 && confirm("Load new notifications?")){
                this.getNotifications();
            }
        });
        console.log('Initialise');
    }

    closeModal() {
        this.close.emit();
    }

    getNotifications() {
        this.api.getPlayerNotifications(this.getAll).subscribe(res => {
            this.notifications = res.data;
            if (!this.getAll && this.notifications.length > 0) {
                this.markNotificationAsRead();
            }
        });
    }

    ngOnDestroy() {
        this.notificationSubscription.unsubscribe();
    }

    markNotificationAsRead() {
        console.log('Marking as read');
        const notificationIDs = [];
        this.notifications.forEach(notification => {
            notificationIDs.push(notification.notificationID);
        });
        if (notificationIDs.length > 0) {
            this.api.postReadNotifications(notificationIDs).subscribe(res => {
                console.log('Marked as read');
                this.notifications.forEach(notification => {
                    notification.isRead = true;
                });
            });
        }
    }
}