///-----------------------------------------------------------------
///   Class:        ApplicationHub
///   
///   Description:  The SignalR hub class which clients connect to in order to
///                 receive live updates. The clients connectionID is maintained in the
///                 database as persistent storage.
///                 
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
using System.Threading.Tasks;
using INFT3970Backend.Models;
using INFT3970Backend.Data_Access_Layer;
using System;

namespace INFT3970Backend.Hubs
{
    public class ApplicationHub : Hub
    {

        /// <summary>
        /// Method when a CamTag client connects to the application hub.
        /// Updates the clients connectionID and sets IsConnected = TRUE
        /// </summary>
        /// <returns></returns>
        public override Task OnConnectedAsync()
        {
            try
            {
                int playerID = int.Parse(Context.GetHttpContext().Request.Query["playerID"]);
                Player player = new Player(playerID);
                player.ConnectionID = Context.ConnectionId;
                PlayerDAL playerDAL = new PlayerDAL();
                playerDAL.UpdateConnectionID(player);
                return base.OnConnectedAsync();
            }
            catch
            {
                return null;
            }
        }




        /// <summary>
        /// Method when a CamTag client disconnects from the application hub.
        /// Updates the clients connectionID = NULL and sets IsConnected = FALSE
        /// </summary>
        /// <param name="exception"></param>
        /// <returns></returns>
        public override Task OnDisconnectedAsync(Exception exception)
        {
            PlayerDAL playerDAL = new PlayerDAL();
            playerDAL.RemoveConnectionID(Context.ConnectionId);
            return base.OnDisconnectedAsync(exception);
        }
    }
}
