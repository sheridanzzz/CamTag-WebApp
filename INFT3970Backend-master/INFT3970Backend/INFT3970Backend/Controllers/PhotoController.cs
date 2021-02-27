///-----------------------------------------------------------------
///   Class:        PhotoController
///   
///   Description:  The API Endpoint for all Photo requests such as
///                 uploading photos, voting on photos etc.
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
using INFT3970Backend.Data_Access_Layer;
using INFT3970Backend.Helpers;
using INFT3970Backend.Hubs;
using INFT3970Backend.Models;
using INFT3970Backend.Models.Errors;
using INFT3970Backend.Models.Requests;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;

namespace INFT3970Backend.Controllers
{

    [ApiController]
    public class PhotoController : ControllerBase
    {
        //The application hub context, used to to invoke client methods anywhere in the code to send out live updates to clients via SignalR
        private readonly IHubContext<ApplicationHub> _hubContext;
        public PhotoController(IHubContext<ApplicationHub> hubContext)
        {
            _hubContext = hubContext;
        }


        





        /// <summary>
        /// Uploads a photo to the database. Sends out notifications to players that a photo must now be voted on.
        /// Returns a response which indicates success or error.
        /// </summary>
        /// <param name="request">The request which contains all the photo information</param>
        /// <returns>Success or error.</returns>
        [HttpPost]
        [Route("api/photo/upload")]
        public ActionResult<Response> Upload(PhotoUploadRequest request)
        {
            try
            {
                //Build the photo object
                Photo uploadedPhoto = new Photo(request.latitude, request.longitude, request.imgUrl, request.takenByID, request.photoOfID);

                //Get the player object from the database
                Response<Player> getPlayerResponse = new PlayerDAL().GetPlayerByID(uploadedPhoto.TakenByPlayerID);
                if (!getPlayerResponse.IsSuccessful())
                    return new Response(getPlayerResponse.ErrorMessage, getPlayerResponse.ErrorCode);

                Response<Photo> response;

                //Call the BR Upload business logic if the player is a BR player
                if (getPlayerResponse.Data.IsBRPlayer())
                    response = new PhotoDAL().SavePhoto(uploadedPhoto, true);

                //Otherwise, call the CORE business logic
                else
                    response = new PhotoDAL().SavePhoto(uploadedPhoto, false);
                
                //If the response is successful we want to send live updates to clients and
                //email or text message notifications to not connected players
                if (response.IsSuccessful())
                {
                    HubInterface hubInterface = new HubInterface(_hubContext);
                    hubInterface.UpdatePhotoUploaded(response.Data);
                    ScheduledTasks.ScheduleCheckPhotoVotingCompleted(response.Data, hubInterface);
                }
                return new Response(response.ErrorMessage, response.ErrorCode);
            }
            //Catch any error associated with invalid model data
            catch (InvalidModelException e)
            {
                return new Response(e.Msg, e.Code);
            }
            //Catch any unhandled / unexpected server errrors
            catch
            {
                return StatusCode(500);
            }
        }








        /// <summary>
        /// Gets the list of Vote records which have not been completed by the player.
        /// This is the list of photos which the player has not voted on yet.
        /// </summary>
        /// <param name="playerID">The ID of the player</param>
        /// <returns>A list of votes the player must vote on.</returns>
        [HttpGet]
        [Route("api/photo/vote")]
        public ActionResult<Response<List<Vote>>> GetVotesToComplete([FromHeader] int playerID)
        {
            try
            {
                Player player = new Player(playerID);
                //Call the Data Access Layer to get the photos require voting to be completed
                Response<List<Vote>> response = new PhotoDAL().GetVotesToComplete(player);

                //If the response was successful compress the response before sending the data over the network
                if(response.IsSuccessful())
                {
                    foreach (var vote in response.Data)
                        vote.Compress();
                }

                return response;
            }
            //Catch any error associated with invalid model data
            catch (InvalidModelException e)
            {
                return new Response<List<Vote>>(e.Msg, e.Code);
            }
            //Catch any unhandled / unexpected server errrors
            catch
            {
                return StatusCode(500);
            }
        }








        /// <summary>
        /// Cast a vote on a photo. Decide if the photo is a successful photo or unsuccessful.
        /// </summary>
        /// <param name="playerID">The ID of the player making the vote.</param>
        /// <param name="voteID">The ID of the vote record being updated.</param>
        /// <param name="decision">The decision, TRUE = successful, FALSE = unsuccessful</param>
        /// <returns>Success or error.</returns>
        [HttpPost]
        [Route("api/photo/vote")]
        public ActionResult<Response> VoteOnPhoto([FromHeader] int playerID, [FromHeader] int voteID, [FromForm] string decision)
        {
            try
            {
                //Get the player object from the database
                Response<Player> getPlayerResponse = new PlayerDAL().GetPlayerByID(playerID);
                if (!getPlayerResponse.IsSuccessful())
                    return new Response(getPlayerResponse.ErrorMessage, getPlayerResponse.ErrorCode);

                Vote vote = new Vote(voteID, decision, playerID);
                Response<Vote> response;

                //Vote on the photo
                response = new PhotoDAL().VoteOnPhoto(vote, getPlayerResponse.Data.IsBRPlayer());
                if (response.IsSuccessful())
                {
                    //If the response's data is NULL that means the game is now completed for a BR game. Send live updates to complete the game
                    if(response.Data == null)
                    {
                        HubInterface hubInterface = new HubInterface(_hubContext);
                        hubInterface.UpdateGameCompleted(getPlayerResponse.Data.Game, false);
                    }

                    //If the Photo's voting has now been completed send the notifications / updates
                    else if (response.Data.Photo.IsVotingComplete)
                    {
                        HubInterface hubInterface = new HubInterface(_hubContext);
                        hubInterface.UpdatePhotoVotingCompleted(response.Data.Photo);
                    }
                }
                return new Response(response.ErrorMessage, response.ErrorCode);
            }
            //Catch any error associated with invalid model data
            catch (InvalidModelException e)
            {
                return new Response(e.Msg, e.Code);
            }
            //Catch any unhandled / unexpected server errrors
            catch
            {
                return StatusCode(500);
            }
        }
    }
}
