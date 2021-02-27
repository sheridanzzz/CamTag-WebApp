///-----------------------------------------------------------------
///   Class:        Notification
///   
///   Description:  A model which represents a Notification in CamTag.
///                 Maps to the data found in the Database.
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
    public class Notification
    {
        public int NotificationID { get; set; }
        public string MessageText { get; set; }
        public string Type { get; set; }
        public bool IsRead { get; set; }
        public bool IsActive { get; set; }
        public bool IsDeleted { get; set; }
        public int GameID { get; set; }
        public int PlayerID { get; set; }
        public Game Game { get; set; }
        public Player Player { get; set; }
    }
}
