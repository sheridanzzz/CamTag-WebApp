///-----------------------------------------------------------------
///   Class:        ReadNotificationsRequest
///   
///   Description:  An object which encapsulates a request sent by the 
///                 front end when reading notification. The front end
///                 will create a JSON object and send the object
///                 to the back end. The JSON object translates to this object.
///                 
///                 When a player reads their unread notifications it
///                 marks all the notifications as read. This class
///                 includes an array of all notifications to mark
///                 as read.
///   
///   Authors:      Team 6
///                 Jonathan Williams
///                 Dylan Levin
///                 Mathew Herbert
///                 David Low
///                 Harry Pallet
///                 Sheridan Gomes
///-----------------------------------------------------------------
namespace INFT3970Backend.Models
{
    public class ReadNotificationsRequest
    {
        public string PlayerID { get; set; }
        public string[] NotificationArray { get; set; }
    }
}
