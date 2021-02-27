///-----------------------------------------------------------------
///   Class:        HubInterface
///   
///   Description:  A class which provides an interface to the SignalR hub
///                 in order to send live updates to clients connected to
///                 the web application. Provides methods to update clients
///                 for many different scenarios such as a player joining the game,
///                 leaving the game, a photo has been uploaded etc.
///                 
///                 The live updates are methods being invoked on the client
///                 to handle the different scenarios. So whenever a client
///                 is updated by the command:
///                 hubContext.Clients.Client(player.ConnectionID).SendAsync("methodName");
///                 will invoke a method on the client.
///   
///   Authors:      Team 6
///                 Jonathan Williams
///                 Dylan Levin
///                 Mathew Herbert
///                 David Low
///                 Harry Pallet
///                 Sheridan Gomes
///-----------------------------------------------------------------

using Microsoft.AspNetCore.SignalR;
using INFT3970Backend.Models;
using INFT3970Backend.Data_Access_Layer;
using System;

namespace INFT3970Backend.Hubs
{
    public class HubInterface
    {

        //The application hub context, used to to invoke client methods anywhere in the code to send out live updates to clients via SignalR
        private readonly IHubContext<ApplicationHub> _hubContext;
        public HubInterface(IHubContext<ApplicationHub> hubContext)
        {
            _hubContext = hubContext;
        }






        /// <summary>
        /// Sends a notification to the players in the game that a new player has joined the game.
        /// 
        /// If the game is currently in the lobby or starting (GameState = IN LOBBY, STARTING) 
        /// then no notification will be sent, the lobby list will be updated.
        /// 
        /// If the game is currently playing (GameState = PLAYING) then a in game notification will be sent to 
        /// the players connect to the hub / have the web app open.
        /// 
        /// An out of game notification will be sent to the players contact (Email or phone) if the player is 
        /// not currently connected to the application hub when GameState = STARTING, PLAYING.
        /// </summary>
        /// <param name="joinedPlayer">The player who joined the game.</param>
        public async void UpdatePlayerJoinedGame(Player joinedPlayer)
        {
            Console.WriteLine("HubInterface - UpdatePlayerJoinedGame");

            //Get all the players currently in the game which are updateable
            GameDAL gameDAL = new GameDAL();
            Response<Game> gameResponse = gameDAL.GetAllPlayersInGame(joinedPlayer.PlayerID, true, "UPDATEABLE", "AZ");

            //If an error occurred while trying to get the list of players exit the method
            if (!gameResponse.IsSuccessful())
                return;

            Game game = gameResponse.Data;

            //Create notifications of new player joining, if the game is playing and the player joining is verified
            if (game.IsPlaying() && joinedPlayer.IsVerified)
                gameDAL.CreateJoinNotification(joinedPlayer);


            //Loop through each of the players and update any player currently in the game.
            foreach (var player in game.Players)
            {
                //If the PlayerID is the playerID who joined skip this iteration
                if (player.PlayerID == joinedPlayer.PlayerID)
                    continue;

                //Update players in game when connected to the hub / have the web app open
                if(player.IsConnected)
                {
                    //If the game is IN LOBBY or STARTING update the lobby list for both verfied and unverified players joining
                    if(game.IsInLobby() || game.IsStarting())
                    {
                        Console.WriteLine("Invoking UpdateGameLobbyList on :" + player.Nickname);
                        await _hubContext.Clients.Client(player.ConnectionID).SendAsync("UpdateGameLobbyList");
                    }
                        

                    //Otherwise, update the players notifications and the scoreboard because they are currently playing the game
                    else if(game.IsPlaying() && joinedPlayer.IsVerified)
                    {
                        Console.WriteLine("Invoking UpdateNotifications and UpdateScoreboard on :" + player.Nickname);
                        await _hubContext.Clients.Client(player.ConnectionID).SendAsync("UpdateNotifications");
                        await _hubContext.Clients.Client(player.ConnectionID).SendAsync("UpdateScoreboard");
                    }
                }
                //Otherwise, the player is out of the app and not a BR player who is eliminated, send them a text message or email.
                else if(!player.IsEliminated)
                {
                    //Only send a notification when the game is playing or starting
                    string message = joinedPlayer.Nickname + " has joined your game of CamTag.";
                    string subject = "New Player Joined Your Game";
                    if ((game.IsPlaying() || game.IsStarting()) && joinedPlayer.IsVerified)
                    {
                        Console.WriteLine("Sending new player joined SMS or Email to:" + player.Nickname);
                        player.ReceiveMessage(message, subject);
                    }
                }
            }
        }

        








        /// <summary>
        /// Updates all the clients either via IN-GAME notifications or notificiations via text/email that
        /// a new photo has been uploaded to their game of CamTag and is ready to be voted on.
        /// </summary>
        /// <param name="uploadedPhoto">The photo which has been uploaded.</param>
        public async void UpdatePhotoUploaded(Photo uploadedPhoto)
        {
            Console.WriteLine("HubInterface - UpdatePhotoUploaded");

            //Get all the players currently in the game which are updateable
            Response<Game> response = new GameDAL().GetAllPlayersInGame(uploadedPhoto.GameID, false, "UPDATEABLE", "AZ");

            //If an error occurred while trying to get the list of players exit the method
            if (!response.IsSuccessful())
                return;


            //Loop through all the players in the game and send a Hub method or send a notification to their contact details.
            foreach(var player in response.Data.Players)
            {
                //If the playerID = the playerID who took the photo or is the playerID who the photo is of, skip this
                //iteration because they will not be voting on the photo and will not receive a notification
                if (player.PlayerID == uploadedPhoto.TakenByPlayerID || player.PlayerID == uploadedPhoto.PhotoOfPlayerID)
                    continue;

                //The player is connected to the Hub, call a live update method
                if(player.IsConnected)
                {
                    Console.WriteLine("Invoking UpdatePhotoUploaded on :" + player.Nickname);
                    await _hubContext.Clients.Client(player.ConnectionID).SendAsync("UpdatePhotoUploaded");
                }

                //Otherwise, the player is not currently in the WebApp, send a notification to their contact details.
                else
                {
                    Console.WriteLine("Sending new photo uploaded SMS or Email to:" + player.Nickname);
                    string message = "A new photo has been uploaded in your game of CamTag. Cast your vote before time runs out!";
                    string subject = "New Photo Submitted";
                    player.ReceiveMessage(message, subject);
                }
            }
        }







        /// <summary>
        /// Sends a notification to the Players in the game that a player has left the game.
        /// If the game is currently in the Lobby (GameState = STARTING) then no notification will be sent, the lobby list will be updated.
        /// If the game is currently playing (GameState = PLAYING) then a notification will be sent to the players in the game.
        /// A notification will be sent to the players contact (Email or phone) if the player is not currently connected to the application hub.
        /// Otherwise, if the player is currently in the app and connected to the hub an InGame notification will be sent to the client.
        /// </summary>
        /// <param name="leftPlayer">The player who left the game</param>
        public async void UpdatePlayerLeftGame(Player leftPlayer)
        {
            Console.WriteLine("HubInterface - UpdatePlayerLeftGame");

            //Get all the players currently in the game which are updateable
            GameDAL gameDAL = new GameDAL();
            Response<Game> gameResponse = gameDAL.GetAllPlayersInGame(leftPlayer.GameID, false, "UPDATEABLE", "AZ");

            //If an error occurred while trying to get the list of players exit the method
            if (!gameResponse.IsSuccessful())
                return;

            Game game = gameResponse.Data;

            //Create notifications of player leaving, if the game is playing
            if (game.IsPlaying())
                gameDAL.CreateLeaveNotification(leftPlayer);

            //Loop through each of the players and update any player currently connected to the hub
            foreach (var player in game.Players)
            {
                //The player is connected to the hub, send live updates
                if (player.IsConnected)
                {
                    //If the game state is IN LOBBY or STARTING then the players are in the Lobby, update the lobby list
                    if (game.IsInLobby() || game.IsStarting())
                    {
                        Console.WriteLine("Invoking UpdateGameLobbyList on :" + player.Nickname);
                        await _hubContext.Clients.Client(player.ConnectionID).SendAsync("UpdateGameLobbyList");
                    }

                    //If the game state is PLAYING - Send a notification to the players in the game.
                    else
                    {
                        Console.WriteLine("Invoking UpdateNotifications and UpdateScoreboard on :" + player.Nickname);
                        await _hubContext.Clients.Client(player.ConnectionID).SendAsync("UpdateNotifications");
                        await _hubContext.Clients.Client(player.ConnectionID).SendAsync("UpdateScoreboard");
                    }
                }

                //Otherwise, the player is not connected to the Hub, send a notification via the contact information
                //only if the player is not a BR player which is eliminated
                else if (!player.IsEliminated)
                {
                    //Don't send a notification when the game is IN LOBBY or STARTING state
                    string message = leftPlayer.Nickname + " has left your game of CamTag.";
                    string subject = "A Player Left Your Game";
                    if (game.IsPlaying() || game.IsStarting())
                    {
                        Console.WriteLine("Sending player left game SMS or Email to :" + player.Nickname);
                        player.ReceiveMessage(message, subject);
                    }
                }
            }
        }







        /// <summary>
        /// Sends updates to players once the game has been completed.
        /// Will send a notification to Phone/Email if the players arnt connected to the hub.
        /// If the players are connected to the hub a hub method will be invoked.
        /// </summary>
        /// <param name="game">The game which was completed</param>
        /// <param name="isNotEnoughPlayers">A flag if the game ended because too many players left the game.</param>
        public async void UpdateGameCompleted(Game game, bool isNotEnoughPlayers)
        {
            Console.WriteLine("HubInterface - UpdateGameCompleted");

            //Get the list of players from the game
            Response<Game> response = new GameDAL().GetAllPlayersInGame(game.GameID, false, "ALL", "AZ");

            if (!response.IsSuccessful())
                return;

            //Loop through each of the players and send out the notifications
            foreach(var player in response.Data.Players)
            {
                //Since the game is now completed needed to get all players. 
                //If they have left the game, have not been verified or deleted do not send them a notification
                if (player.HasLeftGame || !player.IsVerified || player.IsDeleted)
                    continue;

                //If the player is currently connected to the application send them a live update
                if (player.IsConnected)
                {
                    Console.WriteLine("Invoking GameCompleted on :" + player.Nickname);
                    await _hubContext.Clients.Client(player.ConnectionID).SendAsync("GameCompleted");
                }

                //Otherwise, send them a text message or email letting them know the game is completed
                else
                {
                    Console.WriteLine("Sending game completed SMS or Email to :" + player.Nickname);
                    string message = "Your game of CamTag has been completed. Thanks for playing!";
                    string subject = "Game Completed";
                    if (isNotEnoughPlayers)
                        message = "Your game of CamTag has been completed because there is no longer enough players in your game. Thanks for playing!";
                    player.ReceiveMessage(message, subject);
                }
            }
        }






        /// <summary>
        /// Sends out live updates to the all players currently in the lobby that the lobby is now ended 
        /// because the host player left the lobby.
        /// </summary>
        /// <param name="game">The game being ended.</param>
        public async void UpdateLobbyEnded(Game game)
        {
            Console.WriteLine("HubInterface - UpdateLobbyEnded");

            //Get the list of players from the game
            Response<Game> response = new GameDAL().GetAllPlayersInGame(game.GameID, false, "ALL", "AZ");
            if (!response.IsSuccessful())
                return;

            //Loop through each of the players and send out the live update
            foreach(var player in response.Data.Players)
            {
                if (player.IsConnected && !player.IsHost)
                {
                    Console.WriteLine("Invoking LobbyEnded on :" + player.Nickname);
                    await _hubContext.Clients.Client(player.ConnectionID).SendAsync("LobbyEnded");
                }
            }
        }






        /// <summary>
        /// Send an update to a player that their ammo has been replenished.
        /// A text/mail notification will only be sent out when a player's ammo has gone from 0 to 1.
        /// </summary>
        /// <param name="player">The player being updated.</param>
        public async void UpdateAmmoReplenished(Player player)
        {
            Console.WriteLine("HubInterface - UpdateAmmoReplenished");

            //If the players ammo has gone from 0-1 create a notification for the player
            if (player.AmmoCount == 1)
            {
                //Create an ammo notification
                Response response = new GameDAL().CreateAmmoNotification(player);

                //If the ammo notification was not successful leave the method
                if (!response.IsSuccessful())
                    return;
            }
                
            
            //If the player is connected to the hub call the UpdateNotifications and the AmmoReplenished client methods
            if (player.IsConnected)
            {
                Console.WriteLine("Invoking AmmoReplenished on :" + player.Nickname);

                //To indcate to the client that the ammo has increased to update the UI
                await _hubContext.Clients.Client(player.ConnectionID).SendAsync("AmmoReplenished");

                //If the ammo count is now 1, there will be an ammo notificaiton
                if (player.AmmoCount == 1)
                {
                    Console.WriteLine("Invoking UpdateNotifications on :" + player.Nickname);
                    await _hubContext.Clients.Client(player.ConnectionID).SendAsync("UpdateNotifications");
                }
            }

            //Otherwise if ammo has gone from empty to not, send out a text message or email
            else if (player.AmmoCount == 1)
            {
                Console.WriteLine("Sending ammo replenished SMS or Email to :" + player.Nickname);
                string message = "Your ammo has now been replenished, go get em!";
                string subject = "Ammo Replenished";
                player.ReceiveMessage(message, subject);
            }
        }





        /// <summary>
        /// Update a specific player for them to update their notification counter.
        /// </summary>
        /// <param name="playerID"></param>
        public async void UpdateNotificationsRead(int playerID)
        {
            Console.WriteLine("HubInterface - UpdateNotificationsRead");

            //Get the player from the database
            Response<Player> response = new PlayerDAL().GetPlayerByID(playerID);
            if (!response.IsSuccessful())
                return;

            //If the player is connected to the hub update the notifications list
            if (response.Data.IsConnected)
            {
                Console.WriteLine("Invoking UpdateNotifications on :" + response.Data.Nickname);
                await _hubContext.Clients.Client(response.Data.ConnectionID).SendAsync("UpdateNotifications");
            }
        }





        /// <summary>
        /// Sends an update to players that the game is now in a PLAYING state, so the players
        /// can take photos etc. Will send updates via the Hub to connected clients or via
        /// email / text if the player is not connected.
        /// </summary>
        /// <param name="game">The Game which is now playing</param>
        public async void UpdateGameNowPlaying(Game game)
        {
            Console.WriteLine("HubInterface - UpdateGameNowPlaying");

            //Get the list of players from the game
            Response<Game> response = new GameDAL().GetAllPlayersInGame(game.GameID, false, "INGAME", "AZ");

            if (!response.IsSuccessful())
                return;

            //Loop through each of the players and invoke the Hub method or send out a notification that the game has started
            foreach(var player in response.Data.Players)
            {
                //If the player is connected invoke the hub method
                if (player.IsConnected)
                {
                    Console.WriteLine("Invoking GameNowPlaying on :" + player.Nickname);
                    await _hubContext.Clients.Client(player.ConnectionID).SendAsync("GameNowPlaying");
                }

                //Otherwise, send an email/text message notification
                else
                {
                    Console.WriteLine("Sending game now playing SMS or Email to :" + player.Nickname);
                    string message = "Your game of CamTag is now playing. Go tag other players!";
                    string subject = "Game Now Playing";
                    player.ReceiveMessage(message, subject);
                }
            }
        }

        




        /// <summary>
        /// Sends an update to players that the game is now in a STARTING state, so the host
        /// player has clicked "begin game" and the Game will start in 10 mins. It will send
        /// updates to players via the Hub or email / text if the player is not connected.
        /// </summary>
        /// <param name="game">The Game which has now started.</param>
        public async void UpdateGameInStartingState(Game game)
        {
            Console.WriteLine("HubInterface - UpdateGameInStartingState");

            //Get the list of players from the game
            Response<Game> response = new GameDAL().GetAllPlayersInGame(game.GameID, false, "INGAME", "AZ");

            if (!response.IsSuccessful())
                return;

            //Loop through each of the players and invoke the Hub method or send out a notification that the game will begin soon
            foreach (var player in response.Data.Players)
            {
                //If the player is connected invoke the hub method
                if (player.IsConnected)
                {
                    Console.WriteLine("Invoking GameStarting on :" + player.Nickname);
                    await _hubContext.Clients.Client(player.ConnectionID).SendAsync("GameStarting");
                }

                //Otherwise, send an email/text message notification
                else
                {
                    Console.WriteLine("Sending game starting SMS or Email to :" + player.Nickname);
                    string message = "Your game of CamTag will begin at: " + game.StartTime.Value.ToString("dd/MM/yyyy HH:mm:ss tt");
                    string subject = "Game Starting Soon";
                    player.ReceiveMessage(message, subject);
                }
            }
        }






        //BATTLE ROYALE HUB METHODS
        //-------------------------------------------------------------------------------------------------------------------------
        //-------------------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Update a specific player that they have now been disabled for taking a photo outside of the BR playing zone.
        /// </summary>
        /// <param name="player">The player being disabled.</param>
        /// <param name="totalMinutesDisabled">The number of minutes being disabled.</param>
        public async void BR_UpdatePlayerDisabled(Player player, int totalMinutesDisabled)
        {
            Console.WriteLine("HubInterface - BR_UpdatePlayerDisabled");

            //Update the player if they are connected to the application
            if (player.IsConnected)
            {
                Console.WriteLine("Invoking UpdateNotifications and PlayerDisabled on :" + player.Nickname);
                await _hubContext.Clients.Client(player.ConnectionID).SendAsync("UpdateNotifications");
                await _hubContext.Clients.Client(player.ConnectionID).SendAsync("PlayerDisabled", totalMinutesDisabled);
            }
            else
            {
                Console.WriteLine("Sending player disabled SMS or Email to :" + player.Nickname);
                player.ReceiveMessage("You have been disabled for " + totalMinutesDisabled + " minutes for taking a photo outside of the zone.", "You Have Been Disabled");
            }
        }






        /// <summary>
        /// Update a specific player that they have now been re-enabled and can take photos again.
        /// </summary>
        /// <param name="player">The player being re-enabled</param>
        public async void BR_UpdatePlayerReEnabled(Player player)
        {
            Console.WriteLine("HubInterface - BR_UpdatePlayerReEnabled");

            //Get the player from the database as this will run after a certain amount of time.
            //Get the most updated player information
            Response<Player> response = new PlayerDAL().GetPlayerByID(player.PlayerID);
            if (!response.IsSuccessful())
                return;

            player = response.Data;

            //Update the player if they are connected to the application
            if (player.IsConnected)
            {
                Console.WriteLine("Invoking UpdateNotifications and PlayerReEnabled on :" + player.Nickname);
                await _hubContext.Clients.Client(player.ConnectionID).SendAsync("UpdateNotifications");
                await _hubContext.Clients.Client(player.ConnectionID).SendAsync("PlayerReEnabled");
            }
            else
            {
                Console.WriteLine("Sending player re-enabled SMS or Email to :" + player.Nickname);
                player.ReceiveMessage("You have been re-enabled, go get em!", "You Have Been Re-enabled");
            }
        }





        /// <summary>
        /// Update all players in the game that a photo's voting has now been completed.
        /// Send out notifications to the tagged and tagging players and all other players.
        /// </summary>
        /// <param name="photo">The photo which has now been completed.</param>
        public async void UpdatePhotoVotingCompleted(Photo photo)
        {
            Console.WriteLine("HubInterface - UpdatePhotoVotingCompleted");

            //Generate the messages to be sent
            string takenByMsgTxt = "";
            string photoOfMsgTxt = "";
            string subject = "Voting Complete";

            GenerateVotingCompleteMessages(photo, ref takenByMsgTxt, ref photoOfMsgTxt);

            //Generate the notifications
            bool isBR = photo.Game.IsBR();
            if (isBR)
                new GameDAL().CreateTagResultNotification(photo, true);
            else
                new GameDAL().CreateTagResultNotification(photo, false);

            //If the TakenByPlayer is not connected to the application send an out of game notification
            if (!photo.TakenByPlayer.IsConnected)
                photo.TakenByPlayer.ReceiveMessage(takenByMsgTxt, subject);

            //If the PhotoOfPlayer is not connected to the application send an out of game notification
            if (!photo.PhotoOfPlayer.IsConnected)
                photo.PhotoOfPlayer.ReceiveMessage(photoOfMsgTxt, subject);

            //Live update all other clients connected to the application
            //Get all the players currently in the game which are updateable
            Response<Game> response = new GameDAL().GetAllPlayersInGame(photo.GameID, false, "UPDATEABLE", "AZ");
            if (!response.IsSuccessful())
                return;

            //Loop through each player and send the live in game update to update the notifications
            foreach(var player in response.Data.Players)
            {
                //If the player is not connected then continue
                if (!player.IsConnected)
                    continue;

                //If the player is the PhotoOfPlayer and the Photo was successful and it is a BR game, send out eliminated updated
                if (player.PlayerID == photo.PhotoOfPlayerID && photo.IsSuccessful && isBR)
                {
                    Console.WriteLine("Invoking PlayerEliminated on :" + player.Nickname);
                    await _hubContext.Clients.Client(player.ConnectionID).SendAsync("PlayerEliminated");
                }

                //Otherwise, just update the notifications
                else
                {
                    Console.WriteLine("Invoking UpdateNotifications on :" + player.Nickname);
                    await _hubContext.Clients.Client(player.ConnectionID).SendAsync("UpdateNotifications");
                }

                //Update the scoreboard
                Console.WriteLine("Invoking UpdateScoreboard on :" + player.Nickname);
                await _hubContext.Clients.Client(player.ConnectionID).SendAsync("UpdateScoreboard");
            }
        }





        /// <summary>
        /// Helper method for UpdateVotingCompleted which generates the notification messages
        /// for the tagging and tagged player depending on if the game is BR game or not.
        /// </summary>
        /// <param name="completedPhoto">The photo which has been completed</param>
        /// <param name="takenByMessage">The output param which is the message to send to the tagging player</param>
        /// <param name="photoOfMessage">The output param which is the message to send to the tagged player</param>
        private void GenerateVotingCompleteMessages(Photo completedPhoto, ref string takenByMessage, ref string photoOfMessage)
        {
            //If the completed photo is apart of a BR game process the BR Eliminated message
            if(completedPhoto.Game.IsBR())
            {
                //If the photo was successful set the eliminated message
                if(completedPhoto.IsSuccessful)
                {
                    takenByMessage = "You have eliminated " + completedPhoto.PhotoOfPlayer.Nickname + ".";
                    photoOfMessage = "You have been eliminated by " + completedPhoto.TakenByPlayer.Nickname + ".";
                }
                //Otherwise, set the unsuccessful photo
                else
                {
                    takenByMessage = "You did not successfully tag " + completedPhoto.PhotoOfPlayer.Nickname + " because other players voted \"No\" on the photo you submitted.";
                    photoOfMessage = completedPhoto.TakenByPlayer.Nickname + " failed to tag you.";
                }
            }

            //Otherwise, the game is apart of a normal CORE game, process the normal messages
            else
            {
                //If the yes votes are greater than the no votes the the photo is successful
                if (completedPhoto.IsSuccessful)
                {
                    takenByMessage = "You have successfully tagged " + completedPhoto.PhotoOfPlayer.Nickname + ".";
                    photoOfMessage = "You have been tagged by " + completedPhoto.TakenByPlayer.Nickname + ".";
                }
                //Otherwise, the photo was not successful
                else
                {
                    takenByMessage = "You did not successfully tag " + completedPhoto.PhotoOfPlayer.Nickname + " because other players voted \"No\" on the photo you submitted.";
                    photoOfMessage = completedPhoto.TakenByPlayer.Nickname + " failed to tag you.";
                }
            }
        }
    }
}
