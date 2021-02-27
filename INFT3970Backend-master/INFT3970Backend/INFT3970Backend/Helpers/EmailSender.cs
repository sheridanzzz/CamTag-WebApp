///-----------------------------------------------------------------
///   Class:        EmailSender
///   
///   Description:  A helper class used to send emails.
///   
///   Authors:      Team 6
///                 Jonathan Williams
///                 Dylan Levin
///                 Mathew Herbert
///                 David Low
///                 Harry Pallet
///                 Sheridan Gomes
///-----------------------------------------------------------------

using System.Net;
using System.Net.Mail;
using System.Threading;

namespace INFT3970Backend.Helpers
{
    public static class EmailSender
    {
        //The email address used to send emails.
        private const string From = "team6.camtag@gmail.com";
        private const string FromName = "CamTag";
        private const string Username = "team6.camtag";
        private const string Password = "admin123!";



        /// <summary>
        /// Sends an email to the specified address.
        /// This is the private method which actually sends the email.
        /// </summary>
        /// <param name="sendTo">Who to send the email to.</param>
        /// <param name="subject">The subject of the email.</param>
        /// <param name="body">The body of the email.</param>
        /// <param name="isHTML">A flag value which indicates if the email is HTML formatted.</param>
        /// <returns>TRUE if successfully sent. False otherwise.</returns>
        private static bool SendEmail(string sendTo, string subject, string body, bool isHTML)
        {
            SmtpClient SmtpClient;
            MailMessage Mail;
            MailAddress Address;
            SmtpClient = new SmtpClient();
            Mail = new MailMessage();
            Address = new MailAddress(From, FromName);
            SmtpClient.Host = "smtp.gmail.com";
            SmtpClient.Port = 587;
            SmtpClient.EnableSsl = true;
            SmtpClient.DeliveryMethod = SmtpDeliveryMethod.Network;
            SmtpClient.UseDefaultCredentials = false;
            SmtpClient.Credentials = new NetworkCredential(Username, Password);
            bool isSuccessful = false;

            //Try and send the email to the destination email using the subject and body.
            //If any exception occurs return false
            try
            {
                Mail.IsBodyHtml = isHTML;
                Mail.From = Address;
                Mail.To.Add(new MailAddress(sendTo));
                Mail.Subject = subject;
                Mail.Body = body;
                SmtpClient.Send(Mail);
                isSuccessful = true;
            }
            catch
            {
                isSuccessful = false;
            }

            return isSuccessful;
        }




        /// <summary>
        /// The public interface to send an email to the specfied address.
        /// Sends the email in a new thread in order to improve request performance
        /// because sending emails does take time so it is being sent in the background.
        /// </summary>
        /// <param name="sendTo">Who to send the email to.</param>
        /// <param name="subject">The subject of the email.</param>
        /// <param name="body">The body of the email.</param>
        /// <param name="isHTML">A flag value which indicates if the email is HTML formatted.</param>
        public static void Send(string sendTo, string subject, string body, bool isHTML)
        {
            Thread emailThread = new Thread(
                () => SendEmail(sendTo, subject, body, isHTML)
                );
            emailThread.Start();
        }
    }
}
