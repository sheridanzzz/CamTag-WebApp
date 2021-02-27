///-----------------------------------------------------------------
///   Class:        DataAccessLayer
///   
///   Description:  The DataAccessLayer superclass which all DALs extend from.
///                 Provides all the properties and methods required to run 
///                 stored procedures, add parameters, read parameters etc.
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
using System.Data;
using System.Data.SqlClient;

namespace INFT3970Backend.Data_Access_Layer
{
    public class DataAccessLayer
    {
        //The connection string to the database
        //protected const string ConnectionString = @"Server=.\SQLEXPRESS;Database=udb_CamTag;Trusted_Connection=True;";
        protected const string ConnectionString = @"Server=.\SQLEXPRESS;Database=udb_CamTag;User Id=DataAccessLayerLogin;Password=test";

        //The error message returned when an exception is thrown when tryig to connect to the DB and run a stored procedure
        protected const string DatabaseErrorMSG = "An error occurred while trying to connect to the database.";


        /// <summary>
        /// The connection to the database using the connection string
        /// </summary>
        protected SqlConnection Connection { get; set; }


        /// <summary>
        /// The Command being run EG the Stored Procedure + Connection
        /// </summary>
        protected SqlCommand Command { get; set; }


        /// <summary>
        /// The reader object produced by the Command when reading data from SELECT statements
        /// </summary>
        protected SqlDataReader Reader { get; set; }


        /// <summary>
        /// The StoredProcedure name being called
        /// </summary>
        protected string StoredProcedure { get; set; }


        /// <summary>
        /// The result of the stored procedure execution 1 = successful, anthing else = an error occurred
        /// </summary>
        protected int Result { get; set; }


        /// <summary>
        /// The error message returned by the stored procedure
        /// </summary>
        protected string ErrorMSG { get; set; }


        /// <summary>
        /// The error code return by the stored procedure
        /// </summary>
        protected int ErrorCode { get; set; }


        /// <summary>
        /// The flag which outlines if an error occurred while running the stored procedure
        /// </summary>
        protected bool IsError                              
        {
            get
            {
                if (Result != 1)
                    return true;
                else
                    return false;
            }
        }




        /// <summary>
        /// Run the stored procedure with no reader, just using the success or error as the result
        /// </summary>
        protected void Run()
        {
            Command.CommandType = CommandType.StoredProcedure;
            Connection.Open();
            Command.ExecuteNonQuery();
        }




        /// <summary>
        /// Run the stored procedure with a reader to read rows returned from the stored procedure.
        /// </summary>
        protected void RunReader()
        {
            Command.CommandType = CommandType.StoredProcedure;
            Connection.Open();
            Reader = Command.ExecuteReader();
        }




        /// <summary>
        /// Add the default parameters such as result and errorMsg to the stored procedures parameters list.
        /// </summary>
        protected void AddDefaultParams()
        {
            Command.Parameters.Add("@result", SqlDbType.Int);
            Command.Parameters["@result"].Direction = ParameterDirection.Output;
            Command.Parameters.Add("@errorMSG", SqlDbType.VarChar, 255);
            Command.Parameters["@errorMSG"].Direction = ParameterDirection.Output;
        }




        /// <summary>
        /// Read the result and errorMsg value returned from the stored procedure.
        /// </summary>
        protected void ReadDefaultParams()
        {
            Result = Convert.ToInt32(Command.Parameters["@result"].Value);
            ErrorMSG = Convert.ToString(Command.Parameters["@errorMSG"].Value);
        }




        /// <summary>
        /// Add an input parameter to the stored procedure
        /// </summary>
        /// <param name="name">The name of the parameter.</param>
        /// <param name="value">The value being added to the input parameter</param>
        protected void AddParam(string name, object value)
        {
            Command.Parameters.AddWithValue("@" + name, value);
        }



        /// <summary>
        /// Add an output parameter to the stored procedure.
        /// </summary>
        /// <param name="name">The name of the output parameter</param>
        /// <param name="type">The data type of the output parameter</param>
        protected void AddOutput(string name, SqlDbType type)
        {
            if(type == SqlDbType.VarChar)
            {
                Command.Parameters.Add("@" + name, SqlDbType.VarChar, 255);
                Command.Parameters["@" + name].Direction = ParameterDirection.Output;
            }
            else
            {
                Command.Parameters.Add("@" + name, type);
                Command.Parameters["@" + name].Direction = ParameterDirection.Output;
            }
        }
    }
}
