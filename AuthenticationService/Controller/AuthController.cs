using AuthenticationService.DTOs;
using AuthenticationService.Service;
using Microsoft.AspNetCore.Mvc;
using Swashbuckle.AspNetCore.Annotations;
using System.ComponentModel.DataAnnotations;

namespace AuthenticationService.Controller {

    /// <summary>
    /// Authentication API Controller
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    [Produces("application/json")]
    [Tags("Authentication")]
    public class AuthController: ControllerBase {
        private readonly AuthService _authService;

        public AuthController(AuthService authService) {
            _authService = authService;
        }

        /// <summary>
        /// Register a new user
        /// </summary>
        /// <param name="request">User registration details</param>
        /// <returns>Authentication response with token</returns>
        /// <response code="200">User registered successfully</response>
        /// <response code="400">Invalid request or user already exists</response>
        /// <response code="500">Internal server error</response>
        [HttpPost("register")]
        [SwaggerOperation(
            Summary = "Register new user",
            Description = "Creates a new user account and returns authentication token"
        )]
        [SwaggerResponse(200, "User registered successfully", typeof(AuthResponse))]
        [SwaggerResponse(400, "Bad request - validation failed or user exists")]
        [SwaggerResponse(500, "Internal server error")]
        public async Task<ActionResult<AuthResponse>> Register([FromBody] RegisterDTO request) {
            try
            {
                var response = await _authService.Register(request);
                return Ok(response);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        /// <summary>
        /// User login
        /// </summary>
        /// <param name="request">User login credentials</param>
        /// <returns>Authentication response with token</returns>
        /// <response code="200">Login successful</response>
        /// <response code="401">Invalid credentials</response>
        /// <response code="400">Invalid request</response>
        [HttpPost("login")]
        [SwaggerOperation(
            Summary = "User login",
            Description = "Authenticates user credentials and returns access token"
        )]
        [SwaggerResponse(200, "Login successful", typeof(AuthResponse))]
        [SwaggerResponse(401, "Invalid credentials")]
        [SwaggerResponse(400, "Bad request - validation failed")]
        public async Task<ActionResult<AuthResponse>> Login([FromBody] LoginDTO request) {
            try
            {
                var response = await _authService.Login(request);
                if (response == null)
                {
                    return Unauthorized(new { message = "Invalid credentials" });
                }
                return Ok(response);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        /// <summary>
        /// Get current user profile
        /// </summary>
        /// <returns>Current user information</returns>
        /// <response code="200">User profile retrieved successfully</response>
        /// <response code="401">Unauthorized - token required</response>
        [HttpGet("profile")]
        [SwaggerOperation(
            Summary = "Get user profile",
            Description = "Retrieves current authenticated user's profile information"
        )]
        [SwaggerResponse(200, "User profile retrieved successfully")]
        [SwaggerResponse(401, "Unauthorized - valid token required")]
        public async Task<ActionResult> GetProfile()
        {
            // This will be implemented with JWT authentication
            return Ok(new { message = "Profile endpoint - JWT implementation pending" });
        }

        /// <summary>
        /// Health check for authentication service
        /// </summary>
        /// <returns>Service health status</returns>
        [HttpGet("ping")]
        [SwaggerOperation(
            Summary = "Service health check",
            Description = "Simple ping endpoint to verify service is running"
        )]
        [SwaggerResponse(200, "Service is healthy")]
        public ActionResult Ping()
        {
            return Ok(new { 
                message = "Authentication Service is running", 
                timestamp = DateTime.UtcNow,
                version = "1.0.0"
            });
        }
    }
}