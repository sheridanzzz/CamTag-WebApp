///-----------------------------------------------------------------
///   Class:        GameStatusResponse
///   
///   Description:  An object which encapsulates a response sent by the 
///                 back end when the front end views the map.
///                 
///                 This response is returned when a client request
///                 the map view, the response contains a list
///                 of the last photos taken by each player as well
///                 as BR information if applicable
///   
///   Authors:      Team 6
///                 Jonathan Williams
///                 Dylan Levin
///                 Mathew Herbert
///                 David Low
///                 Harry Pallet
///                 Sheridan Gomes
///-----------------------------------------------------------------

using System.Collections.Generic;

namespace INFT3970Backend.Models.Responses
{
    public class MapResponse
    {
        public List<Photo> Photos { get; set; }
        public bool IsBR { get; set; }
        public double Radius { get; set; }
        public double Latitude { get; set; }
        public double Longitude { get; set; }
    }
}
