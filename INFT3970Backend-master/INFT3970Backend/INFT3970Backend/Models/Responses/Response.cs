///-----------------------------------------------------------------
///   Class:        Response
///   
///   Description:  A Response is the response sent to the Frontend in 
///                 order to outline if the request sent to the Backend 
///                 was successfully executed or an error occurred. 
///                 A response can be SUCCESS or ERROR.
/// 
///                 If the Response is SUCCESS - The ErrorCode will be 1, the ErrorMessage will be empty string.
///                 If the Response is ERRROR - The ErrorCode will be anything but 1, and the ErrorMessage will outline the error.
///   
///   Authors:      Team 6
///                 Jonathan Williams
///                 Dylan Levin
///                 Mathew Herbert
///                 David Low
///                 Harry Pallet
///                 Sheridan Gomes
///-----------------------------------------------------------------

namespace INFT3970Backend.Models
{
    public class Response
    {
        /// <summary>
        /// READONLY: The type of Response, SUCCESS or ERROR.
        /// </summary>
        public string Type
        {
            get
            {
                if (ErrorCode == 1)
                    return "SUCCESS";
                else
                    return "ERROR";
            }
        }


        /// <summary>
        /// The error message which outlines why the request failed.
        /// </summary>
        public string ErrorMessage { get; set; }


        /// <summary>
        /// The error code. 1 = SUCCESS, Anything else = ERROR
        /// </summary>
        public int ErrorCode { get; set; }          



        /// <summary>
        /// Creates a SUCCESS response.
        /// </summary>
        public Response()
        {
            ErrorMessage = "";
            ErrorCode = 1;
        }



        /// <summary>
        /// Creates a response with the errorMessage and errorCode passed in. 
        /// If anything other than 1 is passed in the response will be an ERROR.
        /// </summary>
        /// <param name="errorMessage">The error message.</param>
        /// <param name="errorCode">The error code. 1 = SUCCESS, Anything else = ERROR</param>
        public Response(string errorMessage, int errorCode)
        {
            ErrorMessage = errorMessage;
            ErrorCode = errorCode;
        }



        /// <summary>
        /// Determine if the Response is a SUCCESS or ERROR
        /// </summary>
        /// <returns>TRUE if response is SUCCESS, FALSE otherwise.</returns>
        public bool IsSuccessful()
        {
            if (Type == "SUCCESS")
                return true;
            else
                return false;
        }


        /// <summary>
        /// Create a response which is used when a database connection error occurred.
        /// </summary>
        /// <returns></returns>
        public static Response DatabaseErrorResponse()
        {
            return new Response("An error occurred while trying to connect to the database.", ErrorCodes.DATABASE_CONNECT_ERROR);
        }
    }










    /// <summary>
    /// A Generic Response is a subclass of the base Response class.
    /// This subclass allows "Data" to be sent back to the Frontend for the Frontend to use and consume.
    /// 
    /// If the Response is SUCCESS - The ErrorCode will be 1, the ErrorMessage will be empty string and the Data will be an object.
    /// If the Response is ERRROR - The ErrorCode will be anything but 1, and the ErrorMessage will outline the error and the Data will be the DEFAULT value for the object type.
    /// </summary>
    public class Response<T> : Response
    {
        /// <summary>
        /// The data/object being returned to the Frontend when the request was successfully completed.
        /// </summary>
        public T Data { get; set; }

        

        /// <summary>
        /// Creates a successful response with the passed in Data
        /// </summary>
        /// <param name="data">The data/object to assign to the response.</param>
        public Response(T data)
            : base()
        {
            Data = data;
        }



        /// <summary>
        /// Creates a response with the errorMessage and errorCode passed in. 
        /// If anything other than 1 is passed in the response will be an ERROR.
        /// Will use the default value for the Data type.
        /// </summary>
        /// <param name="errorMessage">The error message</param>
        /// <param name="errorCode">The error code. 1 = SUCCESS, Anything else = ERROR</param>
        public Response(string errorMessage, int errorCode)
            : base(errorMessage, errorCode)
        {
            Data = default(T);
        }




        /// <summary>
        /// Creates a response with the errorMessage and errorCode passed in. 
        /// If anything other than 1 is passed in the response will be an ERROR.
        /// Will assign the Response the Data passed in.
        /// </summary>
        /// <param name="data">The data/object to assign to the response.</param>
        /// <param name="errorMessage">The error message</param>
        /// <param name="errorCode">The error code. 1 = SUCCESS, Anything else = ERROR</param>
        public Response(T data, string errorMessage, int errorCode)
            : base(errorMessage, errorCode)
        {
            Data = data;
        }

        public new static Response<T> DatabaseErrorResponse()
        {
            return new Response<T>("An error occurred while trying to connect to the database.", ErrorCodes.DATABASE_CONNECT_ERROR);
        }
    }
}
