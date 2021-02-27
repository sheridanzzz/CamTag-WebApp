///-----------------------------------------------------------------
///   Class:        PhotoUploadRequest
///   
///   Description:  An object which encapsulates a request sent by the 
///                 front end when uploading a photo. The front end
///                 will create a JSON object and send the object
///                 to the back end. The JSON object translates to this object.
///                 
///                 This class matches all the information required
///                 when a player takes a photo.
///   
///   Authors:      Team 6
///                 Jonathan Williams
///                 Dylan Levin
///                 Mathew Herbert
///                 David Low
///                 Harry Pallet
///                 Sheridan Gomes
///-----------------------------------------------------------------
namespace INFT3970Backend.Models.Requests
{
    public class PhotoUploadRequest
    {
        public string imgUrl { get; set; }
        public string takenByID { get; set; }
        public string photoOfID { get; set; }
        public string latitude { get; set; }
        public string longitude { get; set; }
    }
}
