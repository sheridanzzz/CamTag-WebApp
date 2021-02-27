///-----------------------------------------------------------------
///   Class:        TextMessageSender
///   
///   Description:  A helper class used to send text messages via the Twilio API.
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
using System.Threading;
using Twilio;
using Twilio.Rest.Api.V2010.Account;
using Twilio.Types;

namespace INFT3970Backend.Helpers
{
    public static class TextMessageSender
    {
        //The API tokens to send text messages.
        private const string AccountSID = "AC95bc5549490e573dd2ce6941b436d72e";
        private const string AuthToken = "c186c1cbcf2840de60493eaabbce181c";
        private const string TwilioNumber = "+61408929181";



        /// <summary>
        /// Sends a text message to the specified number.
        /// </summary>
        /// <param name="messageText">The text message to send.</param>
        /// <param name="sendTo">The number to send it too.</param>
        /// <returns>TRUE if successfully sent. False otherwise.</returns>
        private static bool SendMessage(string messageText, string sendTo)
        {
            try
            {
                TwilioClient.Init(AccountSID, AuthToken);
                var message = MessageResource.Create(
                body: messageText,
                from: "CamTag",
                to: new PhoneNumber(sendTo)
                );
                Console.WriteLine("Text Message Successfully Sent...");
                return true;
            }
            catch
            {
                Console.WriteLine("An error occurred while trying to send the text message...");
                return false;
            }
        }



        /// <summary>
        /// The public interface to send an text message to the specfied number.
        /// Sends the text in a new thread in order to improve request performance
        /// because sending text does take time so it is being sent in the background.
        /// </summary>
        /// <param name="msgTxt">The text message to send.</param>
        /// <param name="sendTo">The number to send it too.</param>
        public static void Send(string msgTxt, string sendTo)
        {
            Thread txtMsgThread = new Thread(
                () => SendMessage(msgTxt, sendTo)
                );
            txtMsgThread.Start();
        }
    }
}
