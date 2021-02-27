///-----------------------------------------------------------------
///   Class:        Game
///   
///   Description:  A model which represents a CamTag game.
///                 Maps to the data found in the Database and
///                 provides business logic and functionality
///                 such as calculating the current BR radius,
///                 generating a GameCode etc.
///   
///   Authors:      Team 6
///                 Jonathan Williams
///                 Dylan Levin
///                 Mathew Herbert
///                 David Low
///                 Harry Pallet
///                 Sheridan Gomes
///-----------------------------------------------------------------

using INFT3970Backend.Models.Errors;
using System;
using System.Collections.Generic;
using System.Device.Location;
using System.Text.RegularExpressions;

namespace INFT3970Backend.Models
{
    public class Game
    {
        //Minutes / Days in milliseconds, used for the timers
        const int ONE_MINUTE_MILLISECONDS = 60000;
        const int TEN_MINUTES_MILLISECONDS = 600000;
        const int ONE_HOUR_MILLISECONDS = 3600000;
        const int ONE_DAY_MILLISECONDS = 86400000;


        //Private backing stores of public properites which have business logic behind them.
        private int gameID;
        private string gameCode;
        private string gameMode;
        private string gameState;
        private int numOfPlayers;
        private int timeLimit;
        private int ammoLimit;
        private int replenishAmmoDelay;
        private int startDelay;
        private double longitude;
        private double latitude;
        private int radius;



        /// <summary>
        /// The ID of the Game.
        /// </summary>
        public int GameID
        {
            get { return gameID; }
            set
            {
                string errorMSG = "GameID is invalid. Must be atleast 100000.";

                //Confirm the gameID is within the valid range. Can be -1 when creating a game without and ID yet.
                if (value == -1 || value >= 100000)
                    gameID = value;
                else
                    throw new InvalidModelException(errorMSG, ErrorCodes.MODELINVALID_GAME);
            }
        }



        /// <summary>
        /// The unique GameCode which players use to join the game
        /// </summary>
        public string GameCode
        {
            get { return gameCode; }
            set
            {
                string errorMSG = "GameCode is invalid. Must be 6 characters long and only contain letters and numbers.";

                //Confirm the GameCode is a valid value
                if (value == null)
                    throw new InvalidModelException(errorMSG, ErrorCodes.MODELINVALID_GAME);

                Regex gameCodeRegex = new Regex(@"^[a-zA-Z0-9]{6,6}$");
                if (!gameCodeRegex.IsMatch(value))
                    throw new InvalidModelException(errorMSG, ErrorCodes.MODELINVALID_GAME);
                else
                    gameCode = value;
            }
        }



        /// <summary>
        /// The number of players in the game.
        /// </summary>
        public int NumOfPlayers
        {
            get { return numOfPlayers; }
            set
            {
                string errorMSG = "Number of players is invalid, cannot be less than 0 or greater than 16.";

                //Confirm the value is within valid range
                if (value < 0 || value > 16)
                    throw new InvalidModelException(errorMSG, ErrorCodes.MODELINVALID_GAME);
                else
                    numOfPlayers = value;
            }
        }



        /// <summary>
        /// The game mode, either CORE or BR
        /// </summary>
        public string GameMode
        {
            get { return gameMode; }
            set
            {
                string errorMSG = "Game mode is invalid.";

                //Confirm the GameMode is a valid value
                if (value == null)
                    throw new InvalidModelException(errorMSG, ErrorCodes.MODELINVALID_GAME);

                string uppercaseValue = value.ToUpper();

                if (uppercaseValue == "CORE" || uppercaseValue == "BR")
                    gameMode = uppercaseValue;
                else
                    throw new InvalidModelException(errorMSG, ErrorCodes.MODELINVALID_GAME);
            }
        }



        /// <summary>
        /// The State of the game, either IN LOBBY, STARTING, PLAYING or COMPLETED
        /// </summary>
        public string GameState
        {
            get { return gameState; }
            set
            {
                string errorMSG = "Game state is invalid.";


                //Confirm the Gamestate is a valid value
                if (value == null)
                    throw new InvalidModelException(errorMSG, ErrorCodes.MODELINVALID_GAME);

                string uppercaseValue = value.ToUpper();

                if (uppercaseValue == "IN LOBBY" || uppercaseValue == "STARTING" || uppercaseValue == "PLAYING" || uppercaseValue == "COMPLETED")
                    gameState = uppercaseValue;
                else
                    throw new InvalidModelException(errorMSG, ErrorCodes.MODELINVALID_GAME);
            }
        }




        /// <summary>
        /// The time limit of the game. Must be at least 10 minutes and not greater than 24 hours. Stored in milliseconds
        /// </summary>
        public int TimeLimit
        {
            get { return timeLimit; }
            set
            {
                string errorMSG = "Time limit is invalid, must be between 10 minutes and 24 hours.";

                //The time limit of the game can only be between 10 minutes and one day
                if (value < TEN_MINUTES_MILLISECONDS || value > ONE_DAY_MILLISECONDS)
                    throw new InvalidModelException(errorMSG, ErrorCodes.MODELINVALID_GAME);
                else
                    timeLimit = value;
            }
        }




        /// <summary>
        /// The ammo limit each player has, how many photos a player can take before having to wait to be replenished.
        /// </summary>
        public int AmmoLimit
        {
            get { return ammoLimit; }
            set
            {
                string errorMSG = "Ammo limit is invalid. Must be between 1 and 9.";

                //confirm the ammo limit passed in is within the valid range
                if (value < 1 || value > 9)
                    throw new InvalidModelException(errorMSG, ErrorCodes.MODELINVALID_GAME);
                else
                    ammoLimit = value;
            }
        }





        /// <summary>
        /// The time delay for ammo to replenish, so after a player takes a photo how long the ammo will replenish.
        /// Stored as milliseconds.
        /// </summary>
        public int ReplenishAmmoDelay
        {
            get { return replenishAmmoDelay; }
            set
            {
                string errorMSG = "Reload ammo timer is invalid. Must be between 1 minute and 1 hour.";

                //confirm the replenish ammo deley passed in is within the valid range
                //The valid range is between 1 minute and 1 hour
                if (value < ONE_MINUTE_MILLISECONDS || value > ONE_HOUR_MILLISECONDS)
                    throw new InvalidModelException(errorMSG, ErrorCodes.MODELINVALID_GAME);
                else
                    replenishAmmoDelay = value;
            }
        }




        /// <summary>
        /// The time delay before the game moves to a playing state.
        /// When the host player clicks start game how long it takes for the game to start playing.
        /// Stored in milliseconds
        /// </summary>
        public int StartDelay
        {
            get { return startDelay; }
            set
            {
                string errorMSG = "Start delay is invalid. Must be between 1 minute and 10 minutes.";

                //confirm the start deley passed in is within the valid range
                //The valid range is between 1 minute and 10 minutes
                if (value < ONE_MINUTE_MILLISECONDS || value > TEN_MINUTES_MILLISECONDS)
                    throw new InvalidModelException(errorMSG, ErrorCodes.MODELINVALID_GAME);
                else
                    startDelay = value;
            }
        }




        /// <summary>
        /// The lat value of the center point for a Battle Royale game
        /// </summary>
        public double Latitude
        {
            get { return latitude; }
            set
            {
                string errorMessage = "Latitude is not within the valid range. Must be -90 to +90";

                //Confirm the lat is within the valid range
                if (value >= -90 && value <= 90)
                    latitude = value;
                else
                    throw new InvalidModelException(errorMessage, ErrorCodes.MODELINVALID_PHOTO);
            }
        }



        /// <summary>
        /// The long value of the center point for a Battle Royale game
        /// </summary>
        public double Longitude
        {
            get { return longitude; }
            set
            {
                string errorMessage = "Longitude is not within the valid range. Must be -180 to +180";

                if (value >= -180 && value <= 180)
                    longitude = value;

                else
                    throw new InvalidModelException(errorMessage, ErrorCodes.MODELINVALID_GAME);
            }
        }



        /// <summary>
        /// The radius of the starting zone for a Battle Royale game
        /// </summary>
        public int Radius
        {
            get { return radius; }
            set
            {
                //If the game is CORE disregard this value, does not need error checking
                if(GameMode == "CORE")
                {
                    radius = value;
                    return;
                }

                string errorMessage = "Radius is not within the valid range. Must be a minimum of 20 meters.";

                //Confirm the radius is within the valid range
                if (value >= 20)
                    radius = value;
                else
                    throw new InvalidModelException(errorMessage, ErrorCodes.MODELINVALID_GAME);
            }
        }


        /// <summary>
        /// The DateTime of when the game will begin playing
        /// </summary>
        public DateTime? StartTime { get; set; }

        /// <summary>
        /// The DateTime when the game will end
        /// </summary>
        public DateTime? EndTime { get; set; }

        /// <summary>
        /// A flag which outlines if the game is joinable at anytime
        /// </summary>
        public bool IsJoinableAtAnytime { get; set; }

        /// <summary>
        /// A flag if the game is active
        /// </summary>
        public bool IsActive { get; set; }

        /// <summary>
        /// A flag if the game is deleted
        /// </summary>
        public bool IsDeleted { get; set; }

        /// <summary>
        /// The list of players within the game.
        /// </summary>
        public List<Player> Players { get; set; }





        /// <summary>
        /// Creates a game with default values
        /// </summary>
        public Game()
        {
            GameID = -1;
            GameCode = "abc123";
            GameMode = "CORE";
            GameState = "IN LOBBY";
            TimeLimit = ONE_DAY_MILLISECONDS;
            AmmoLimit = 3;
            StartDelay = TEN_MINUTES_MILLISECONDS;
            ReplenishAmmoDelay = TEN_MINUTES_MILLISECONDS;
        }


        /// <summary>
        /// Creates a game with default values and sets the GameCode
        /// </summary>
        /// <param name="gameCode">The 6 digit game code of the game.</param>
        public Game(string gameCode) : this()
        {
            GameCode = gameCode;
        }



        /// <summary>
        /// Creates a game and sets all the passed in values
        /// </summary>
        /// <param name="gameCode">The game code</param>
        /// <param name="timeLimit">The time limit</param>
        /// <param name="ammoLimit">The ammo limit</param>
        /// <param name="startDelay">The start delay</param>
        /// <param name="replenishAmmoDelay">The ammo replenish delay</param>
        /// <param name="gameMode">The game mode</param>
        /// <param name="isJoinableAtAnyTime">A flag if the game is joinable at any time</param>
        /// <param name="latitude">The lat value of the center point for BR</param>
        /// <param name="longitude">The long value of the center point for BR</param>
        /// <param name="radius">The starting radius for the zone for BR</param>
        public Game(string gameCode, int timeLimit, int ammoLimit, int startDelay, int replenishAmmoDelay, string gameMode, bool isJoinableAtAnyTime, double latitude, double longitude, int radius) : this()
        {
            GameCode = gameCode;
            TimeLimit = timeLimit;
            AmmoLimit = ammoLimit;
            StartDelay = startDelay;
            ReplenishAmmoDelay = replenishAmmoDelay;
            GameMode = gameMode;
            IsJoinableAtAnytime = isJoinableAtAnyTime;
            Latitude = latitude;
            Longitude = longitude;
            Radius = radius;
        }



        /// <summary>
        /// Creates a game with default values and set the GameID
        /// </summary>
        /// <param name="gameID">The ID of the game</param>
        public Game(int gameID) : this()
        {
            GameID = gameID;
        }




        /// <summary>
        /// Generates a 6 digit alphanumeric code which is the game code for the game.
        /// </summary>
        /// <returns>6 digit alphanumeric code</returns>
        public static string GenerateGameCode()
        {
            char[] chars = "abcdefghijklmnopqrstuvwxyz1234567890".ToCharArray();
            string gameCode = string.Empty;
            Random random = new Random();

            for (int i = 0; i < 6; i++)
            {
                int x = random.Next(0, chars.Length);
                //For avoiding repetition of Characters
                if (!gameCode.Contains(chars.GetValue(x).ToString()))
                    gameCode += chars.GetValue(x);
                else
                    i = i - 1;
            }
            return gameCode;
        }




        /// <summary>
        /// Calculates the time the player will be disabled when attempting to take a photo
        /// outside of the playing zone in a BR game. The time to be disbaled will be 5% of the
        /// time limit, but the value will be adjusted if not within the valid range.
        /// So the minimum time a player can be disabled is 2mins and the max it 30mins
        /// </summary>
        /// <returns>The number of minutes the player will be disabled for</returns>
        public int CalculateDisabledTime()
        {
            double totalMilliseconds = EndTime.Value.Subtract(StartTime.Value).TotalMilliseconds;

            //Calculate 5% of the total milliseconds
            double millisecondsDisabled = totalMilliseconds * 0.05;

            //Get the minutes of the disabled milliseconds
            int minutesToBeDisabled = TimeSpan.FromMilliseconds(millisecondsDisabled).Minutes;

            //The floor of the disabled minutes is 2, the ceiling of the disabled minutes is 30
            if (minutesToBeDisabled < 2)
                minutesToBeDisabled = 2;
            else if (minutesToBeDisabled > 30)
                minutesToBeDisabled = 30;

            return minutesToBeDisabled;
        }



        /// <summary>
        /// Calculates the current BR radius of the game.
        /// Uses the percentage of time remaining in the game.
        /// So if there is 60% time remaining left in the game
        /// the BR radius will be 60% of the original size.
        /// However, the minimum radius is 20 meters, so if the
        /// radius calculated is less than that it will be adjusted.
        /// </summary>
        /// <returns>The current radius of the BR game.</returns>
        public double CalculateRadius()
        {
            try
            {
                //Get the number of milliseconds between the start and end time
                TimeSpan span = EndTime.Value.Subtract(StartTime.Value);
                double totalTime = span.TotalMilliseconds;

                //Get the time between the current time and the end time
                span = EndTime.Value.Subtract(DateTime.Now);
                double timeRemaining = span.TotalMilliseconds;

                //Calculate the percentage of time remaining
                double percentage = timeRemaining / totalTime;

                //get the current radius
                double currentRadius = Radius * percentage;

                //If the radius ratio/percentage is less than 20 meters, just return 20 meters
                if (currentRadius < 20)
                    currentRadius = 20;
                return currentRadius;
            }
            catch
            {
                return -1;
            }
        }




        /// <summary>
        /// Confirms the latitude and longitude passed in is within the playing zone.
        /// </summary>
        /// <param name="latitude">The lat value to check</param>
        /// <param name="longitude">The long value to check</param>
        /// <returns>TRUE if the passed in values is within the zone, FALSE otherwise</returns>
        public bool IsInZone(double latitude, double longitude)
        {
            //Get the center location of the BR game using the Lat and Long stored in the game
            GeoCoordinate centerLocation = new GeoCoordinate(Latitude, Longitude);

            //Get the location of the Lat and Long passed in
            GeoCoordinate playerLocation = new GeoCoordinate(latitude, longitude);

            //Get the distance in meters
            double distanceBetweenCoords = centerLocation.GetDistanceTo(playerLocation);

            //Get the current radius of the zone
            double currentRadius = CalculateRadius();

            //If the distance between the two points is greater than the radius the player is outside the zone
            if (distanceBetweenCoords > currentRadius)
                return false;
            else
                return true;
        }



        /// <summary>
        /// Check if the game is in a PLAYING state
        /// </summary>
        /// <returns></returns>
        public bool IsPlaying()
        {
            return GameState == "PLAYING";
        }


        /// <summary>
        /// Check if the game is in a STARTING state
        /// </summary>
        public bool IsStarting()
        {
            return GameState == "STARTING";
        }


        /// <summary>
        /// Check if the game is in a IN LOBBY state
        /// </summary>
        public bool IsInLobby()
        {
            return GameState == "IN LOBBY";
        }


        /// <summary>
        /// Check if the game is in a COMPLETED state
        /// </summary>
        public bool IsCompleted()
        {
            return GameState == "COMPLETED";
        }


        /// <summary>
        /// Check if the game is BR game.
        /// </summary>
        public bool IsBR()
        {
            return GameMode == "BR";
        }



        /// <summary>
        /// Compress the Game object when being sent over the network.
        /// So if the game contains a list of players compress the player objects
        /// </summary>
        public void Compress()
        {
            if (Players == null)
                return;
            if (Players.Count == 0)
                return;

            foreach(Player player in Players)
                player.Compress(true, false, true);
        }
    }
}
