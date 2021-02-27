///-----------------------------------------------------------------
///   Class:        PlayerController
///   
///   Description:  The API Endpoint for all Player requests such as
///                 joining a game, verifying a player, leaving a game etc.
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
using Microsoft.AspNetCore.Mvc;
using INFT3970Backend.Models;
using INFT3970Backend.Models.Requests;
using Microsoft.AspNetCore.SignalR;
using INFT3970Backend.Hubs;
using INFT3970Backend.Models.Errors;
using INFT3970Backend.Data_Access_Layer;
using INFT3970Backend.Helpers;
using System;

namespace INFT3970Backend.Controllers
{
    [ApiController]
    public class PlayerController : ControllerBase
    {
        //The application hub context, used to to invoke client methods anywhere in the code to send out live updates to clients via SignalR
        private readonly IHubContext<ApplicationHub> _hubContext;
        public PlayerController(IHubContext<ApplicationHub> hubContext)
        {
            _hubContext = hubContext;
        }






        /// <summary>
        /// Joins a new player to a game matching the game code passed in. Stores their player details 
        /// and sends them a verification code once they have joined the game.
        /// Returns the created Player object.
        /// </summary>
        /// <param name="request">The request which contains the player information and the GameCode to join.</param>
        /// <returns>Returns the created Player object.</returns>
        [HttpPost]
        [Route("api/player/joinGame")]
        public ActionResult<Response<Player>> JoinGame(JoinGameRequest request)
        {
            try
            {
                //Create the player object who will be joining the game
                Player playerToJoin = new Player(request.nickname, request.imgUrl, request.contact);
                Game gameToJoin = new Game(request.gameCode);

                //Generate a verification code 
                int verificationCode = Player.GenerateVerificationCode();

                //Call the data access layer to add the player to the database
                Response<Player> response = new PlayerDAL().JoinGame(gameToJoin, playerToJoin, verificationCode);

                //If the response was successful, send the verification code to the player and update the lobby list
                if (response.IsSuccessful())
                {
                    string message = "Your CamTag verification code is: " + verificationCode;
                    string subject = "CamTag Verification Code";
                    response.Data.ReceiveMessage(message, subject);

                    //Call the hub interface to invoke client methods to update the clients that another player has joined
                    HubInterface hubInterface = new HubInterface(_hubContext);
                    hubInterface.UpdatePlayerJoinedGame(response.Data);

                    //Compress the player data before sending back over the network
                    response.Data.Compress(true, true, true);
                }
                return response;
            }
            //Catch any error associated with invalid model data
            catch (InvalidModelException e)
            {
                return new Response<Player>(e.Msg, e.Code);
            }
            //Catch any unhandled / unexpected server errrors
            catch
            {
                return StatusCode(500);
            }
        }







        /// <summary>
        /// Validates a players received verification code. If the player successfully enters their 
        /// verification code their player record will be verified, meaning they have confirmed their 
        /// email address or phone number is correct and has access to it throughout the game.
        /// </summary>
        /// <param name="verificationCode">The code received and entered by the player</param>
        /// <param name="playerID">The playerID trying to verify</param>
        /// <returns>Success or error.</returns>
        [HttpPost]
        [Route("api/player/verify")]
        public ActionResult<Response> VerifyPlayer([FromForm] string verificationCode, [FromHeader] int playerID)
        {
            try
            {
                Player playerToVerify = new Player(playerID);

                //Confirm the verification code is valid and return an error response if the verification code is invalid
                int code = Player.ValidateVerificationCode(verificationCode);
                if(code == -1)
                    return new Response("The verification code is invalid. Must be an INT between 10000 and 99999.", ErrorCodes.DATA_INVALID);

                //Call the data access layer to confirm the verification code is correct.
                Response<Player> response = new PlayerDAL().ValidateVerificationCode(code, playerToVerify);

                //If the player was successfully verified, updated all the clients about a joined player.
                if (response.IsSuccessful())
                {
                    HubInterface hubInterface = new HubInterface(_hubContext);
                    hubInterface.UpdatePlayerJoinedGame(response.Data);
                }

                return response;
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
        /// Generates a new verification code for the player, updates the verification code in the database
        /// and resends the new code to the player's contact information (Email or Phone).
        /// </summary>
        /// <param name="playerID">The playerID who's verification code is being updated</param>
        /// <returns>Success or error.</returns>
        [HttpPost]
        [Route("api/player/resend")]
        public ActionResult<Response> ResendVerificationCode([FromHeader] int playerID)
        {
            try
            {
                Player player = new Player(playerID);

                //Generate a new code
                int newCode = Player.GenerateVerificationCode();

                //Call the Data Access Layer to update the verification code for the player and 
                //get the contact information for the player
                Response<Player> response = new PlayerDAL().UpdateVerificationCode(player, newCode);

                //If the response is successful send the verification code to the player
                string msgTxt = "Your CamTag verification code is: " + newCode;
                string subject = "CamTag Verification Code";
                if (response.IsSuccessful())
                    response.Data.ReceiveMessage(msgTxt, subject);

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
        /// Gets a list of all the notifications associated with a particular player, ordered by most recent.
        /// </summary>
        /// <param name="playerID">The playerID used to determine which player the notifications are for</param>
        /// <param name="all">A boolean used to determine if all notifications should be fetched or just unread</param>
        /// <returns>The list of notifications.</returns>
        [HttpGet]
        [Route("api/player/getNotifications/{playerID:int}/{all:bool}")]
        public ActionResult<Response<List<Notification>>> GetNotificationList(int playerID, bool all)
        {
            try
            {
                //Call the data access layer to return the notifications for the player.
                Player player = new Player(playerID);
                return new PlayerDAL().GetNotificationList(player, all);
            }
            //Catch any error associated with invalid model data
            catch (InvalidModelException e)
            {
                return new Response<List<Notification>>(e.Msg, e.Code);
            }
            //Catch any unhandled / unexpected server errrors
            catch
            {
                return StatusCode(500);
            }
        }








        /// <summary>
        /// Leaves a player from the game. Will remove any incomplete photos posted by the player,
        /// will remove any incomplete votes the player was required to vote on, will also remove any
        /// unread notifications. If after the player leaves photos have now been completed voting, notifications
        /// will be sent out to players. Also, if after the player leaves the game there is not enough players the
        /// game will end.
        /// </summary>
        /// <param name="playerID">The playerID leaving the game.</param>
        /// <returns>Success or error.</returns>
        [HttpPost]
        [Route("api/player/leaveGame")]
        public ActionResult<Response> LeaveGame([FromHeader] int playerID)
        {
            try
            {
                Player player = new Player(playerID);

                //Get the player who is leaving the game
                PlayerDAL playerDAL = new PlayerDAL();
                Response<Player> getPlayerResponse = playerDAL.GetPlayerByID(playerID);
                if (!getPlayerResponse.IsSuccessful())
                    return new Response(getPlayerResponse.ErrorMessage, getPlayerResponse.ErrorCode);

                player = getPlayerResponse.Data;

                //Create the hub interface which will be used to send live updates to clients
                HubInterface hubInterface = new HubInterface(_hubContext);

                //If the player leaving the game is the host and the game is currently in the lobby kick all other players from the game
                //because only the host player can begin the game
                if (player.IsHost && player.Game.IsInLobby())
                {
                    Response endLobbyResponse = new GameDAL().EndLobby(player.Game);

                    //If successfully kicked all players from the game send live updates to clients that they have been removed from the lobby
                    if(endLobbyResponse.IsSuccessful())
                        hubInterface.UpdateLobbyEnded(player.Game);

                    //Return and leave the method because there is nothing else to process at this point
                    return endLobbyResponse;
                }


                //Call the data access layer to remove the player from the game.
                bool isGameComplete = false;
                bool isPhotosComplete = false;
                Response<List<Photo>> leaveGameResponse = playerDAL.LeaveGame(player, ref isGameComplete, ref isPhotosComplete);

                //Return the error response if an error occurred
                if (!leaveGameResponse.IsSuccessful())
                    return new Response(leaveGameResponse.ErrorMessage, leaveGameResponse.ErrorCode);

                //Call the hub method to send out notifications to players that the game is now complete
                if (isGameComplete)
                    hubInterface.UpdateGameCompleted(player.Game, true);

                //Otherwise, if the photo list is not empty then photos have been completed and need to send out updates
                else if (isPhotosComplete)
                {
                    foreach (var photo in leaveGameResponse.Data)
                        hubInterface.UpdatePhotoVotingCompleted(photo);
                }

                //If the game is not completed send out the player left notification
                if (!isGameComplete)
                    hubInterface.UpdatePlayerLeftGame(player);

                return new Response(leaveGameResponse.ErrorMessage, leaveGameResponse.ErrorCode);
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
        /// Marks a set of player notifications as read.
        /// </summary>
        /// <param name="jsonNotificationIDs">The playerID and notificationIDs to mark as read.</param>
        /// <returns>Success or error.</returns>
        [HttpPost]
        [Route("api/player/setNotificationsRead")]
        public ActionResult<Response> SetNotificationsRead(ReadNotificationsRequest jsonNotificationIDs)
        {
            try
            {
                //Call the data access layer to update the notification records
                Response response = new PlayerDAL().SetNotificationsRead(jsonNotificationIDs);

                //If the response was successful update the client's notifications list
                if (response.IsSuccessful())
                    new HubInterface(_hubContext).UpdateNotificationsRead(Convert.ToInt32(jsonNotificationIDs.PlayerID));

                return response;
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
        /// Uses a players ammo, when a player clicks the take photo button the ammo is reduced by 1
        /// even if the player decides not to take the photo. 
        /// 
        /// If the player is playing a BR game the player is validated to confirm they are inside the playing
        /// zone, if they are not inside the zone the player is disabled and the ammo is still decremented.
        /// </summary>
        /// <param name="playerID">The playerID using ammo/taking a photo.</param>
        /// <param name="latitude">The latitude of the player.</param>
        /// <param name="longitude">The longitude of the player.</param>
        /// <returns>The updated player object, outlining the new ammo count and if the player is now disabled.</returns>
        [HttpPost]
        [Route("api/player/useAmmo")]
        public ActionResult<Response<Player>> UseAmmo([FromHeader] int playerID, [FromForm] double latitude, [FromForm] double longitude)
        {
            try
            {
                //Call the DataAccessLayer to get the player object from the DB
                Response<Player> getPlayerResponse = new PlayerDAL().GetPlayerByID(playerID);
                if (!getPlayerResponse.IsSuccessful())
                    return getPlayerResponse;

                //If the player is a BR player process different, otherwise, process the CORE use ammo
                Player player = getPlayerResponse.Data;
                if (player.IsBRPlayer())
                    return BR_UseAmmoLogic(player, latitude, longitude);

                //Otherwise, process the CORE use ammo logic
                else
                    return CORE_UseAmmoLogic(player);
                
            }
            //Catch any error associated with invalid model data
            catch (InvalidModelException e)
            {
                return new Response<Player>(e.Msg, e.Code);
            }
            //Catch any unhandled / unexpected server errrors
            catch
            {
                return StatusCode(500);
            }
        }







        /// <summary>
        /// Helper method for the UseAmmo request, processes the CORE gamemode business logic for using a players ammo.
        /// </summary>
        /// <param name="player">The player who is using the ammo</param>
        /// <returns>The updated player object outlining the new ammo count.</returns>
        private Response<Player> CORE_UseAmmoLogic(Player player)
        {
            Response<Player> response = new PlayerDAL().UseAmmo(player);

            //If the response was successful schedule code to run in order to replenish the players ammo
            if (response.IsSuccessful())
            {
                HubInterface hubInterface = new HubInterface(_hubContext);
                ScheduledTasks.ScheduleReplenishAmmo(response.Data, hubInterface);

                //Compress the player object before sending back over the network
                response.Data.Compress(true, true, true);
            }
            return response;
        }







        /// <summary>
        /// Helper method for the UseAmmo request, processes the BR gamemode businesss logic.
        /// Will confirm the player is within the playing radius, if not will disable the player.
        /// </summary>
        /// <param name="player">The player who is using the ammo</param>
        /// <param name="latitude">The latitude of the player.</param>
        /// <param name="longitude">The longitude of the player.</param>
        /// <returns></returns>
        private ActionResult<Response<Player>> BR_UseAmmoLogic(Player player, double latitude, double longitude)
        {
            //Decrement the players ammo
            Response<Player> response = new PlayerDAL().UseAmmo(player);
            if (!response.IsSuccessful())
                return response;

            player = response.Data;
            HubInterface hubInterface = new HubInterface(_hubContext);

            //If the player is not within the zone disable the player
            if (!player.Game.IsInZone(latitude, longitude))
            {
                //Calculate the the number of minutes the player will be disabled for
                int totalMinutesDisabled = player.Game.CalculateDisabledTime();
                int totalMillisecondsDisabled = totalMinutesDisabled * 60 * 1000;

                //Disable the player
                response = new PlayerDAL().BR_DisableOrRenablePlayer(player, totalMinutesDisabled);
                if (!response.IsSuccessful())
                    return response;

                player = response.Data;

                //Call the hub to update the client that they are now disabled
                hubInterface.BR_UpdatePlayerDisabled(player, totalMinutesDisabled);

                //Schedule the player to be re-enabled
                ScheduledTasks.BR_SchedulePlayerReEnabled(player, hubInterface, totalMillisecondsDisabled);

                //Set the error code and message to indicate to the client that the player is now disabled.
                response.ErrorMessage = "Not inside the zone.";
                response.ErrorCode = ErrorCodes.BR_NOTINZONE;
            }

            //Schedule the ammo to be replenished
            ScheduledTasks.ScheduleReplenishAmmo(player, hubInterface);
            
            //Compress the player object before sending back over the network
            response.Data.Compress(true, true, true);
            return response;
        }   
        






        /// <summary>
        /// Gets the ammo count for the Player
        /// </summary>
        /// <param name="playerID">The ID of the player</param>
        /// <returns>The ammo count, negative INT if error</returns>
        [HttpGet]
        [Route("api/player/ammo")]
        public ActionResult<Response<int>> GetAmmoCount([FromHeader] int playerID)
        {
            try
            {
                Player player = new Player(playerID);
                return new PlayerDAL().GetAmmoCount(player);
            }
            //Catch any error associated with invalid model data
            catch (InvalidModelException e)
            {
                return new Response<int>(e.Msg, e.Code);
            }
            //Catch any unhandled / unexpected server errrors
            catch
            {
                return StatusCode(500);
            }
        }







        /// <summary>
        /// Gets the count of unread notifications for the player.
        /// </summary>
        /// <param name="playerID">The ID of the player</param>
        /// <returns>The count of unread notifications, negative INT if error</returns>
        [HttpGet]
        [Route("api/player/unread")]
        public ActionResult<Response<int>> GetUnreadNotificationCount([FromHeader] int playerID)
        {
            try
            {
                Player player = new Player(playerID);
                return new PlayerDAL().GetUnreadNotificationsCount(player);
            }
            //Catch any error associated with invalid model data
            catch (InvalidModelException e)
            {
                return new Response<int>(e.Msg, e.Code);
            }
            //Catch any unhandled / unexpected server errrors
            catch
            {
                return StatusCode(500);
            }
        }








        /// <summary>
        /// Removes an unverified player from the game.
        /// This can only be performed when the game is IN LOBBY and can only be performed by
        /// the host player.
        /// </summary>
        /// <param name="playerID">The ID of the requesting player, should be the host playerID</param>
        /// <param name="playerIDToRemove">ID the of the unverified player to remove from the game</param>
        /// <returns>Success or error.</returns>
        [HttpPost]
        [Route("api/player/remove")]
        public ActionResult<Response> RemoveUnverifiedPlayer([FromForm] int playerID, [FromForm] int playerIDToRemove)
        {
            try
            {
                //Create the player submitting the request
                Player playerMakingRequest = new Player(playerID);

                //Create the player to remove
                Player playerToRemove = new Player(playerIDToRemove);

                //Remove the unverified player
                Response<Player> response = new PlayerDAL().RemoveUnverifiedPlayer(playerMakingRequest, playerToRemove);

                //if the response was successful call the hub interface to update the clients
                if(response.IsSuccessful())
                {
                    HubInterface hubInterface = new HubInterface(_hubContext);
                    hubInterface.UpdatePlayerLeftGame(response.Data);
                }

                return new Response(response.ErrorMessage, response.ErrorCode);
            }
            //Catch any error associated with invalid model data
            catch (InvalidModelException e)
            {
                return new Response<int>(e.Msg, e.Code);
            }
            //Catch any unhandled / unexpected server errrors
            catch
            {
                return StatusCode(500);
            }
        }
    }
}
