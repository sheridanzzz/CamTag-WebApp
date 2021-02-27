///-----------------------------------------------------------------
///   Class:        MapController
///   
///   Description:  The API Endpoint for the map requests
///   
///   Authors:      Team 6
///                 Jonathan Williams
///                 Dylan Levin
///                 Mathew Herbert
///                 David Low
///                 Harry Pallet
///                 Sheridan Gomes
///-----------------------------------------------------------------

using INFT3970Backend.Models;
using Microsoft.AspNetCore.Mvc;
using INFT3970Backend.Models.Errors;
using INFT3970Backend.Data_Access_Layer;
using INFT3970Backend.Models.Responses;
using System.Collections.Generic;

namespace INFT3970Backend.Controllers
{
    [ApiController]
    public class Map : ControllerBase
    {

        /// <summary>
        /// Gets all the data required to display the map such as the last photo taken by each player to indicate their
        /// last known location and all their player information to display the selfie image on the screen.
        /// If the game is a BR game, the centre point and the currenct game radius will also be returned.
        /// </summary>
        /// <param name="playerID">The ID of the player making the request</param>
        /// <returns>The list of last photos taken by each player used for the last known locations and all player information.</returns>
        [HttpGet]
        [Route("api/map")]
        public ActionResult<Response<MapResponse>> GetMap([FromHeader] int playerID)
        {
            try
            {
                Player player = new Player(playerID);

                //Get the player from the database
                Response<Player> playerResponse = new PlayerDAL().GetPlayerByID(playerID);
                if (!playerResponse.IsSuccessful())
                    return new Response<MapResponse>(playerResponse.ErrorMessage, playerResponse.ErrorCode);

                //Call the data access layer to get the last known locations
                Response<List<Photo>> getLastPhotoLocationsResponse = new PhotoDAL().GetLastKnownLocations(player);
                if(!getLastPhotoLocationsResponse.IsSuccessful())
                    return new Response<MapResponse>(getLastPhotoLocationsResponse.ErrorMessage, getLastPhotoLocationsResponse.ErrorCode);

                //If the response was successful compress the photo to remove any unneccessary data needed for the map
                foreach (var photo in getLastPhotoLocationsResponse.Data)
                    photo.CompressForMapRequest();

                MapResponse map;

                //if the player is not a BR player return the list of photos
                if (!playerResponse.Data.IsBRPlayer())
                {
                    map = new MapResponse()
                    {
                        Photos = getLastPhotoLocationsResponse.Data,
                        IsBR = false,
                        Latitude = 0,
                        Longitude = 0,
                        Radius = 0
                    };
                }

                //otherwise, calculate the currenct radius
                else
                {
                    map = new MapResponse()
                    {
                        Photos = getLastPhotoLocationsResponse.Data,
                        IsBR = true,
                        Latitude = playerResponse.Data.Game.Latitude,
                        Longitude = playerResponse.Data.Game.Longitude,
                        Radius = playerResponse.Data.Game.CalculateRadius()
                    };
                }

                return new Response<MapResponse>(map);
            }
            //Catch any error associated with invalid model data
            catch (InvalidModelException e)
            {
                return new Response<MapResponse>(e.Msg, e.Code);
            }
            //Catch any unhandled / unexpected server errrors
            catch
            {
                return StatusCode(500);
            }
        }
    }   
}

