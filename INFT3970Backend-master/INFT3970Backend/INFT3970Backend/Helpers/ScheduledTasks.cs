///-----------------------------------------------------------------
///   Class:        ScheduledTasks
///   
///   Description:  A helper class used to schedule code to run after a
///                 certain period of time such as scheduling a game to be complete etc.
///   
///   Authors:      Team 6
///                 Jonathan Williams
///                 Dylan Levin
///                 Mathew Herbert
///                 David Low
///                 Harry Pallet
///                 Sheridan Gomes
///-----------------------------------------------------------------

using INFT3970Backend.Data_Access_Layer;
using INFT3970Backend.Hubs;
using INFT3970Backend.Models;
using System;
using System.Threading;

namespace INFT3970Backend.Helpers
{
    public class ScheduledTasks
    {
        /// <summary>
        /// Schedules code to run in a new thread after the game start time has passed in order
        /// to updated a started game to a PLAYING game state.
        /// </summary>
        /// <param name="game">The Game being updated</param>
        /// <param name="hubInterface">The HubInterface used to to send live updates to users.</param>
        public static void ScheduleGameInPlayingState(Game game, HubInterface hubInterface)
        {
            //Get how long to wait for the task to run
            int timeToWait = GetTimeToWait(game.StartTime.Value);

            //Start the Method in a new thread
            Thread ScheduleGameInPlayingStateThread = new Thread(
                () => Run_GameInPlayingState(game, timeToWait, hubInterface)
                );
            ScheduleGameInPlayingStateThread.Start();
        }





        /// <summary>
        /// The code which will run in a new thread after the game start time has passed in order
        /// to updated a started game to a PLAYING game state.
        /// </summary>
        /// <param name="game">The Game being updated</param>
        /// <param name="hubInterface">The HubInterface used to to send live updates to users.</param>
        /// <param name="timeToWait">The number of milliseconds to sleep before the thread starts.</param>
        private static void Run_GameInPlayingState(Game game, int timeToWait, HubInterface hubInterface)
        {
            //Sleep the thread until the game has reached the playing state
            Thread.Sleep(timeToWait);

            //Get the updated game record
            GameDAL gameDAL = new GameDAL();
            Response<Game> gameResponse = gameDAL.GetGameByID(game.GameID);
            if (!gameResponse.IsSuccessful())
                return;

            //Confirm the game is in a starting state and the start time has elapsed
            if (gameResponse.Data.GameState != "STARTING")
                return;
            if (gameResponse.Data.StartTime.Value > DateTime.Now)
                return;

            Response response = gameDAL.SetGameState(game.GameID, "PLAYING");

            //Send updates to clients that the game has now officially begun
            if (response.IsSuccessful())
                hubInterface.UpdateGameNowPlaying(game);
        }









        /// <summary>
        /// Schedules code to run in a new thread after the game finish time has passed in order
        /// to updated the game record to COMPLETED.
        /// </summary>
        /// <param name="game">The Game being updated</param>
        /// <param name="hubInterface">The HubInterface used to to send live updates to users.</param>
        public static void ScheduleCompleteGame(Game game, HubInterface hubInterface)
        {
            //Get how long to wait for the task to run
            int timeToWait = GetTimeToWait(game.EndTime.Value);

            //Start the Method in a new thread
            Thread ScheduleCompleteGameThread = new Thread(
                () => Run_CompleteGame(game, timeToWait, hubInterface)
                );
            ScheduleCompleteGameThread.Start();
        }







        /// <summary>
        /// The code which will run in a new thread after the game finish time has passed in order
        /// to updated the game record to COMPLETED.
        /// </summary>
        /// <param name="game">The Game being updated</param>
        /// <param name="hubInterface">The HubInterface used to to send live updates to users.</param>
        /// <param name="timeToWait">The number of milliseconds to sleep before the thread starts.</param>
        private static void Run_CompleteGame(Game game, int timeToWait, HubInterface hubInterface)
        {
            Thread.Sleep(timeToWait);

            //Call the DataAccessLayer to complete the game in the DB
            GameDAL gameDAL = new GameDAL();
            Response response = gameDAL.CompleteGame(game.GameID);

            //If the response was successful send out the game completed messages to players
            if (response.IsSuccessful())
                hubInterface.UpdateGameCompleted(game, false);
        }









        /// <summary>
        /// Schedules code to run in a new thread after the ammo replenish time has passed in order
        /// to increment the players ammo count.
        /// </summary>
        /// <param name="playerID">The ID of the player being updated.</param>
        /// <param name="hubInterface">The HubInterface used to to send live updates to users.</param>
        public static void ScheduleReplenishAmmo(Player player, HubInterface hubInterface)
        {
            //Get how long to wait for the task to run
            int timeToWait = GetTimeToWait(DateTime.Now.AddMilliseconds(player.Game.ReplenishAmmoDelay));

            //Start the Method in a new thread
            Thread ScheduleReplenishAmmoThread = new Thread(
                () => Run_ReplenishAmmo(player, timeToWait, hubInterface)
                );
            ScheduleReplenishAmmoThread.Start();
        }









        /// <summary>
        /// The code which will run in a new thread after the ammo replenish time has passed in order
        /// to increment the players ammo count.
        /// </summary>
        /// <param name="playerID">The ID of the player being updated.</param>
        /// <param name="hubInterface">The HubInterface used to to send live updates to users.</param>
        /// <param name="timeToWait">The number of milliseconds to sleep before the thread starts.</param>
        private static void Run_ReplenishAmmo(Player player, int timeToWait, HubInterface hubInterface)
        {
            Thread.Sleep(timeToWait);

            //Call the DataAccessLayer to increment the ammo count in the database
            PlayerDAL playerDAL = new PlayerDAL();
            Response<Player> response = playerDAL.ReplenishAmmo(player);

            if (response.IsSuccessful())
            {
                //As the ammo has replenished, send out a notification and update client.
                hubInterface.UpdateAmmoReplenished(response.Data);
            }
        }









        /// <summary>
        /// Schedules code to run in a new thread which will run after the FinishVotingTime has passed.
        /// The method checks to see if all players have voted on the image and if not, will
        /// update the image to be successful and make all votes a success. Then send out notifications
        /// to the affected players. 
        /// </summary>
        /// <param name="uploadedPhoto">The photo which was uploaded and being checked if voting has been completed.</param>
        /// <param name="hubInterface">The Hub interface which will be used to send notifications / updates</param>
        public static void ScheduleCheckPhotoVotingCompleted(Photo uploadedPhoto, HubInterface hubInterface)
        {
            //Get how long to wait for the task to run
            int timeToWait = GetTimeToWait(uploadedPhoto.VotingFinishTime);

            //Start the Method in a new thread
            Thread ScheduleReplenishAmmoThread = new Thread(
                () => Run_CheckPhotoVotingCompleted(uploadedPhoto, timeToWait, hubInterface)
                );
            ScheduleReplenishAmmoThread.Start();
        }








        /// <summary>
        /// The code which will run in a new thread after the FinishVotingTime has passed.
        /// The method checks to see if all players have voted on the image and if not, will
        /// update the image to be successful and make all votes a success. Then send out notifications
        /// to the affected players. 
        /// </summary>
        /// <param name="uploadedPhoto">The photo which was uploaded and being checked if voting has been completed.</param>
        /// <param name="timeToWait">The number of milliseconds to wait for the thread to start.</param>
        /// <param name="hubInterface">The Hub interface which will be used to send notifications / updates</param>
        private static void Run_CheckPhotoVotingCompleted(Photo uploadedPhoto, int timeToWait, HubInterface hubContext)
        {
            //Wait for the specified time
            Thread.Sleep(timeToWait);

            //Get the updated photo record from the database
            Photo photo = new PhotoDAL().GetPhotoByID(uploadedPhoto.PhotoID);
            if (photo == null)
                return;

            //Confirm the game the photo is apart of is not completed, if completed leave the method
            if (photo.Game.IsCompleted())
                return;

            //Check to see if the voting has been completed for the photo.
            //If the voting has been completed exit the method
            if (photo.IsVotingComplete)
                return;

            //Otherwise, the game is not completed and the photo has not been successfully voted on by all players

            //Call the Data Access Layer to update the photo record to now be completed.
            PhotoDAL photoDAL = new PhotoDAL();
            Response<Photo> response = photoDAL.VotingTimeExpired(photo.PhotoID, photo.TakenByPlayer.IsBRPlayer());

            //If the update was successful then send out the notifications to the affected players
            //Will send out in game notifications and text/email notifications
            if (response.IsSuccessful())
            {
                //If the response's data is NULL that means the game is now completed. Send live updates to complete the game
                if (response.Data == null)
                    hubContext.UpdateGameCompleted(photo.Game, false);

                //Otherwise, update the players that voting has been completed
                else
                    hubContext.UpdatePhotoVotingCompleted(response.Data);
            }   
        }







        /// <summary>
        /// Gtes the number of milliseconds from the DateTime passed in and the current DateTime.
        /// </summary>
        /// <param name="waitUntil">The end DateTime</param>
        /// <returns>Number of milliseconds between the current DateTime and the DateTime passed in.</returns>
        private static int GetTimeToWait(DateTime waitUntil)
        {
            DateTime now = DateTime.Now;
            TimeSpan span = waitUntil.Subtract(now);
            return (int)span.TotalMilliseconds;
        }





        /// <summary>
        /// Schedules a player to be re-enabled after a certain period of time after they have been disabled
        /// after being disabled for taking a photo outside of the playing zone in a BR game.
        /// </summary>
        /// <param name="player">The player being re-enabled</param>
        /// <param name="totalMillisecondsDisabled">The number of milliseconds to wait for the thread to start.</param>
        /// <param name="hubInterface">The Hub interface which will be used to send notifications / updates</param>
        public static void BR_SchedulePlayerReEnabled(Player player, HubInterface hubInterface, int totalMillisecondsDisabled)
        {
            int timeToWait = totalMillisecondsDisabled;

            //Start the Method in a new thread
            Thread SchedulePlayerReEnabled = new Thread(
                () => Run_RenablePlayer(player, timeToWait, hubInterface)
                );
            SchedulePlayerReEnabled.Start();
        }



        /// <summary>
        /// The code which will run after the disabled time has elapsed and the player will be re-enabled.
        /// </summary>
        /// <param name="player"></param>
        /// <param name="timeToWait"></param>
        /// <param name="hubInterface"></param>
        private static void Run_RenablePlayer(Player player, int timeToWait, HubInterface hubInterface)
        {
            //Wait for the specified time
            Thread.Sleep(timeToWait);

            //Renable the player
            Response<Player> response = new PlayerDAL().BR_DisableOrRenablePlayer(player, 0);
            if (!response.IsSuccessful())
                return;

            //Call the hub to send an update that the player has now been re-enabled
            hubInterface.BR_UpdatePlayerReEnabled(player);
        }   
    }
}
