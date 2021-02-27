///-----------------------------------------------------------------
///   Class:        Player
///   
///   Description:  A model which represents a Player in CamTag.
///                 Maps to the data found inside the Database and
///                 provides business logic validation and functionality
///                 such as generating verification code and resizing
///                 selfie images etc.
///   
///   Authors:      Team 6
///                 Jonathan Williams
///                 Dylan Levin
///                 Mathew Herbert
///                 David Low
///                 Harry Pallet
///                 Sheridan Gomes
///-----------------------------------------------------------------

using System;
using System.IO;
using System.Text.RegularExpressions;
using INFT3970Backend.Helpers;
using INFT3970Backend.Models.Errors;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.PixelFormats;
using SixLabors.ImageSharp.Processing;

namespace INFT3970Backend.Models
{
    public class Player
    {
        //Private backing stores for public properties
        private int playerID;
        private string nickname;
        private string phone;
        private string email;
        private string selfie;
        private string smallSelfie;
        private string extraSmallSelfie;
        private int ammoCount;
        private int numKills;
        private int numDeaths;
        private int gameID;


        /// <summary>
        /// The ID of the player
        /// </summary>
        public int PlayerID
        {
            get { return playerID; }
            set
            {
                string errorMSG = "PlayerID is invalid. Must be atleast 100000.";

                //Confirm the ID is within the valid range. Can be -1 if creating a player without an ID
                if (value == -1 || value >= 100000)
                    playerID = value;
                else
                    throw new InvalidModelException(errorMSG, ErrorCodes.MODELINVALID_PLAYER);
            }
        }



        /// <summary>
        /// The players nickname
        /// </summary>
        public string Nickname
        {
            get { return nickname; }
            set
            {
                string errorMSG = "The nickname you entered is invalid, please only enter letters and numbers (no spaces).";

                //Confirm the nickname is not null or empty
                if (string.IsNullOrWhiteSpace(value))
                    throw new InvalidModelException(errorMSG, ErrorCodes.MODELINVALID_PLAYER);

                //Confirm the nickname only contains numbers and letters, no special characters.
                Regex nicknameRegex = new Regex(@"^[a-zA-Z0-9]{1,}$");
                bool isMatch = nicknameRegex.IsMatch(value);
                if (!isMatch)
                    throw new InvalidModelException(errorMSG, ErrorCodes.MODELINVALID_PLAYER);
                else
                    nickname = value;
            }
        }



        /// <summary>
        /// The player's contact phone number
        /// </summary>
        public string Phone
        {
            get { return phone; }
            set
            {
                string errorMSG = "Phone number is invalid format.";

                //The phone number can be null, if it is null then return.
                if (string.IsNullOrWhiteSpace(value))
                {
                    phone = null;
                    return;
                }
                   
                //Otherwise, confirm the phone number is in a valid format
                if (!IsPhone(value))
                    throw new InvalidModelException(errorMSG, ErrorCodes.MODELINVALID_PLAYER);
                else
                    phone = value;
            }
        }




        /// <summary>
        /// The players email address
        /// </summary>
        public string Email
        {
            get { return email; }
            set
            {
                string errorMSG = "Email is invalid format.";

                //The email can be null, if it is null then return.
                if (string.IsNullOrWhiteSpace(value))
                {
                    email = null;
                    return;
                }

                //Confirm the email address is in valid format
                if (!IsEmail(value))
                    throw new InvalidModelException(errorMSG, ErrorCodes.MODELINVALID_PLAYER);
                else
                {
                    //If the address is a gmail address then remove the periods because they dont matter.
                    string tempEmail = value;
                    if (value.Contains("@gmail.com"))
                    {
                        string[] emailNoPeriods = value.Split('@');
                        emailNoPeriods[0] = emailNoPeriods[0].Replace(".", "");
                        tempEmail = emailNoPeriods[0] + "@" + emailNoPeriods[1];
                    }
                    email = tempEmail;
                }
            }
        }



        /// <summary>
        /// The player's selfie taken when joining or creating a game. This is the large original size selfie.
        /// </summary>
        public string Selfie
        {
            get { return selfie; }
            set
            {
                string errorMSG = "Selfie DataURL is not a base64 string.";

                //Allow the selfie to be set to null because of compression while sending over the network
                if (value == null)
                {
                    selfie = null;
                    return;
                }

                //Confirm the imgURL is a base64 string
                if (!IsValidDataURL(value))
                    throw new InvalidModelException(errorMSG, ErrorCodes.MODELINVALID_PLAYER);

                selfie = value;
            }
        }


        


        /// <summary>
        /// The player's current ammo count in the game.
        /// </summary>
        public int AmmoCount
        {
            get { return ammoCount; }
            set
            {
                string errorMSG = "Ammo count cannot be less than 0.";

                //Confirm the ammo count is a valid value
                if (value < 0)
                    throw new InvalidModelException(errorMSG, ErrorCodes.MODELINVALID_PLAYER);
                else
                    ammoCount = value;
            }
        }



        /// <summary>
        /// The number of kills or tags a player has. 
        /// </summary>
        public int NumKills
        {
            get { return numKills; }
            set
            {
                string errorMSG = "Number of kills cannot be less than 0.";

                //Confirm the kills is a valid value
                if (value < 0)
                    throw new InvalidModelException(errorMSG, ErrorCodes.MODELINVALID_PLAYER);
                else
                    numKills = value;
            }
        }



        /// <summary>
        /// The number of deaths/number of times this player has been successfully tagged by others
        /// </summary>
        public int NumDeaths
        {
            get { return numDeaths; }
            set
            {
                string errorMSG = "Number of deaths cannot be less than 0.";

                //Confirm the value is valid
                if (value < 0)
                    throw new InvalidModelException(errorMSG, ErrorCodes.MODELINVALID_PLAYER);
                else
                    numDeaths = value;
            }
        }


        /// <summary>
        /// A flag value which indicates if the player has the application open and is connected to the SignalR hub
        /// and can receive live in game updates.
        /// </summary>
        public bool IsConnected
        {
            get
            {
                if (string.IsNullOrWhiteSpace(ConnectionID))
                    return false;
                else
                    return true;
            }
        }



        /// <summary>
        /// The gameID the player is apart of.
        /// </summary>
        public int GameID
        {
            get { return gameID; }
            set
            {
                string errorMSG = "GameID is invalid. Must be atleast 100000.";

                //Confirm the value is valid, can be -1 if creating a player who is not in a game yet.
                if (value == -1 || value >= 100000)
                    gameID = value;
                else
                    throw new InvalidModelException(errorMSG, ErrorCodes.MODELINVALID_PLAYER);
            }
        }


        /// <summary>
        /// The selfie image which is sized at 128px x 128px. This image is used for display in the lobby page.
        /// </summary>
        public string SmallSelfie
        {
            get { return smallSelfie; }
            set
            {
                string errorMSG = "Selfie DataURL is not a base64 string.";

                //Allow the selfie to be set to null because of compression while sending over the network
                if (value == null)
                {
                    smallSelfie = null;
                    return;
                }

                //Confirm the imgURL is a base64 string
                if (!IsValidDataURL(value))
                    throw new InvalidModelException(errorMSG, ErrorCodes.MODELINVALID_PLAYER);

                smallSelfie = value;
            }
        }


        /// <summary>
        /// The selfie image which is sized at 32px by 32px. This image is used for display on the map.
        /// </summary>
        public string ExtraSmallSelfie
        {
            get { return extraSmallSelfie; }
            set
            {
                string errorMSG = "Selfie DataURL is not a base64 string.";

                //Allow the selfie to be set to null because of compression while sending over the network
                if (value == null)
                {
                    extraSmallSelfie = null;
                    return;
                }

                //Confirm the imgURL is a base64 string
                if (!IsValidDataURL(value))
                    throw new InvalidModelException(errorMSG, ErrorCodes.MODELINVALID_PLAYER);

                extraSmallSelfie = value;
            }
        }

        /// <summary>
        /// A flag value to indicate if the player is the host of the game.
        /// </summary>
        public bool IsHost { get; set; }

        /// <summary>
        /// A flag value to indicate if the player has verified their contact details.
        /// </summary>
        public bool IsVerified { get; set; }

        /// <summary>
        /// A flag value to indicate if the player is active.
        /// </summary>
        public bool IsActive { get; set; }

        /// <summary>
        /// A flag value to indicate if the player has been deleted
        /// </summary>
        public bool IsDeleted { get; set; }

        /// <summary>
        /// The unique connectionID assigned to the player when connecting to the signalR hub.
        /// </summary>
        public string ConnectionID { get; set; }

        /// <summary>
        /// A flag to indicate if the player has left the game.
        /// </summary>
        public bool HasLeftGame { get; set; }

        /// <summary>
        /// A flag value to indicate if the player has been eliminated in a BR game.
        /// </summary>
        public bool IsEliminated { get; set; }

        /// <summary>
        /// A flag value to indicate if the player is disabled in a BR game.
        /// </summary>
        public bool IsDisabled { get; set; }

        /// <summary>
        /// Outlines if the player is a CORE player or BR player
        /// </summary>
        public string PlayerType { get; set; }

        /// <summary>
        /// The game the player is apart of
        /// </summary>
        public Game Game { get; set; }
        



        /// <summary>
        /// Creates a Player with the default values
        /// </summary>
        public Player()
        {
            PlayerID = -1;
            GameID = -1;
            Nickname = "Player";
            Selfie = null;
            IsActive = true;
        }





        /// <summary>
        /// Creates a Player with the default values and set the PlayerID
        /// </summary>
        /// <param name="playerID">the ID of the player.</param>
        public Player(int playerID) : this()
        {
            PlayerID = playerID;
        }




        /// <summary>
        /// Creates a Player with the default values and sets the following properties.
        /// </summary>
        /// <param name="nickname">The nickname of the player.</param>
        /// <param name="selfieDataURL">The DataURL of the player's selfie, a base64 string.</param>
        /// <param name="contact">The contact of the player, a phone number or email address.</param>
        public Player(string nickname, string selfieDataURL, string contact) :this()
        {
            Nickname = nickname;
            Selfie = selfieDataURL;

            //Resize the selfie images to the smaller values
            if (!ResizeSelfieImages())
                throw new InvalidModelException("Failed to resize selife images.", ErrorCodes.MODELINVALID_PLAYER);

            //If the number passed in is a phone number replace the 0 with +61 as Twilio requires +61
            if (IsPhone(contact))
                Phone = "+61" + contact.Substring(1);

            else if (IsEmail(contact))
                Email = contact;
            else
                throw new InvalidModelException("Contact is invalid, not a phone number or email address.", ErrorCodes.MODELINVALID_PLAYER);
        }




        /// <summary>
        /// Sends a text or email to the players contact information
        /// </summary>
        /// <param name="msg">The message to send.</param>
        /// <param name="subject">The subject of the message, used when sending emails.</param>
        public void ReceiveMessage(string msg, string subject)
        {
            //Add a footer to the message which includes a link back to the game.
            msg += "\n\nPlease visit theteam6.com to return to your game.";

            //If the player has an email send them an email, otherwise, send to their phone number.
            if (HasEmail())
                EmailSender.Send(Email, subject, msg, false);
            else
                TextMessageSender.Send(msg, Phone);
        }





        /// <summary>
        /// Checks if the player has an email address.
        /// </summary>
        /// <returns>TRUE if email is not null or empty, FALSE otherwise</returns>
        public bool HasEmail()
        {
            if (string.IsNullOrWhiteSpace(Email))
                return false;
            else
                return true;
        }




        /// <summary>
        /// Checks if the player has a phone number.
        /// </summary>
        /// <returns>TRUE if phone number is not null or empty, FALSE otherwise</returns>
        public bool HasPhone()
        {
            if (string.IsNullOrWhiteSpace(Phone))
                return false;
            else
                return true;
        }




        /// <summary>
        /// Checks if the contact passed in is a valid email address.
        /// </summary>
        /// <param name="contact">The possible email address.</param>
        /// <returns>TRUE if the contact is an email address, FALSE otherwise</returns>
        public static bool IsEmail(string contact)
        {
            Regex emailRegex = new Regex(@"^\w+([-+.']\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*$");
            return emailRegex.IsMatch(contact);
        }



        /// <summary>
        /// Checks if the contact passed in is a valid phone number.
        /// </summary>
        /// <param name="contact">The possible phone number.</param>
        /// <returns>TRUE if contact is a valid phone number, FALSE otherwise</returns>
        public static bool IsPhone(string contact)
        {
            bool isNormalPhone = false;
            bool isTwilioPhone = false;

            //Check to see if the phone number is a normal 04 number
            Regex normalPhoneRegex = new Regex(@"^[0-9]{10,10}$");
            isNormalPhone = normalPhoneRegex.IsMatch(contact);

            //Check to see if the phone number is a Twilio +61 number
            Regex twilioPhoneRegex = new Regex(@"^\+61[0-9]{9,9}$");
            isTwilioPhone = twilioPhoneRegex.IsMatch(contact);

            return isNormalPhone || isTwilioPhone;
        }



        /// <summary>
        /// Gets the players contact information.
        /// Will return the email address if the player has an email,
        /// otherwise, phone number is returned.
        /// </summary>
        /// <returns>The email or phone number</returns>
        public string GetContact()
        {
            if (HasEmail())
                return Email;
            else
                return Phone;
        }




        /// <summary>
        /// Confirms the verification code passed in is valid.
        /// Must be between 10000 and 99999
        /// </summary>
        /// <param name="strCode">The code in string format</param>
        /// <returns>The INT code, negative INT if an error occurred or invalid</returns>
        public static int ValidateVerificationCode(string strCode)
        {
            if (string.IsNullOrWhiteSpace(strCode))
                return -1;

            int code = 0;
            try
            {
                //Confirm the code is within the valid range
                code = int.Parse(strCode);
                if (code < 10000 || code > 99999)
                    throw new Exception();
                return code;
            }
            catch
            {
                return -1;
            }
        }


        /// <summary>
        /// Generates a 5 digit verification code between 10000 and 99999
        /// </summary>
        /// <returns>The 5 digit code</returns>
        public static int GenerateVerificationCode()
        {
            Random rand = new Random();
            return rand.Next(10000, 99999);
        }


        /// <summary>
        /// Checks to see if thr player is a BR player
        /// </summary>
        /// <returns>TRUE if player is a BR player, FALSE otherwise</returns>
        public bool IsBRPlayer()
        {
            return PlayerType.ToUpper() == "BR";
        }



        /// <summary>
        /// Resizes the original selfie image to 2 different sizes, small and extra small.
        /// The small is 128x128 and the extra small is 32x32. The images are then assigned to
        /// the corresponding properities of the player.
        /// </summary>
        /// <returns>TRUE if successful, false otherwise</returns>
        public bool ResizeSelfieImages()
        {
            try
            {
                string dataUrlString = "data:image/jpeg;base64,";
                string largeImageBase64Data = Selfie.Replace(dataUrlString, "");
                byte[] largeImageByteData = Convert.FromBase64String(largeImageBase64Data);

                //Reszie the large selfie data to the the smaller versions
                using (Image<Rgba32> image = Image.Load(largeImageByteData))
                {
                    //Resize to the small version
                    image.Mutate(ctx => ctx.Resize(128, 128));
                    using (var stream = new MemoryStream())
                    {
                        //Get the byte data from the image
                        image.Save<Rgba32>(stream, ImageFormats.Jpeg);
                        byte[] smallImageByteArray = stream.ToArray();

                        //Convert it to a base 64 string
                        string smallImageBase64String = Convert.ToBase64String(smallImageByteArray);
                        SmallSelfie = dataUrlString + smallImageBase64String;
                    }

                    //Rezise the image to the extra small version
                    image.Mutate(ctx => ctx.Resize(32, 32));
                    using (var stream = new MemoryStream())
                    {
                        //Get the byte data from the image
                        image.Save<Rgba32>(stream, ImageFormats.Jpeg);
                        byte[] extraSmallImageByteArray = stream.ToArray();

                        //Convert it to a base 64 string
                        string extraSmallImageBase64String = Convert.ToBase64String(extraSmallImageByteArray);
                        ExtraSmallSelfie = dataUrlString + extraSmallImageBase64String;
                    }
                }

                return true;
            }
            catch
            {
                return false;
            }
        }



        /// <summary>
        /// Compress the player for transport over the network. The data to be compressed will the the different selfie images.
        /// The method gives the option to compress certain images as different requests require certain images or non at all.
        /// </summary>
        /// <param name="doCompressLarge">Flag to outline if want to compress the large selfie</param>
        /// <param name="doCompressSmall">Flag to outline if want to compress the small selfie</param>
        /// <param name="doCompressExtraSmall">Flag to outline if want to compress the extra small selfie</param>
        public void Compress(bool doCompressLarge, bool doCompressSmall, bool doCompressExtraSmall)
        {
            //Set the Image DataURL to null if specified to compress
            if(doCompressLarge)
                Selfie = null;

            if(doCompressSmall)
                SmallSelfie = null;

            if(doCompressExtraSmall)
                ExtraSmallSelfie = null;
        }



        /// <summary>
        /// Confirm the passed in DataURL is a valid DataURL and can be converted to a base64 image.
        /// </summary>
        /// <param name="dataURL">The dataURL to validate</param>
        /// <returns>TRUE if valid, FALSE otherwise</returns>
        private bool IsValidDataURL(string dataURL)
        {
            //Confirm the dataURL is a base64 string
            try
            {
                if (!dataURL.Contains("data:image/jpeg;base64,"))
                    return false;

                //Get the byte data from the dataURL, will thrown an exception if in the incorrect format
                string dataUrlString = "data:image/jpeg;base64,";
                string base64Data = dataURL.Replace(dataUrlString, "");
                byte[] byteData = Convert.FromBase64String(base64Data);

                //If reaching this point the image is a valid dataURL
                return true;
            }
            catch
            {
                return false;
            }
        }
    }
}
