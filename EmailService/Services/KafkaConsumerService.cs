using System.Text.Json;
using Confluent.Kafka;
using Microsoft.Extensions.Configuration;

namespace EmailService.Services {
    public class KafkaConsumerService: BackgroundService {
        private readonly IConsumer<string, string> _consumer;
        private readonly IEmailService _emailService;
        private const string Topic = "user-registered";
        private readonly string _bootstrapServers;

        public KafkaConsumerService(IEmailService emailService, IConfiguration config) {
            // Lấy cấu hình Kafka từ IConfiguration
            _bootstrapServers = config["Kafka:BootstrapServers"] ?? "kafka:29092";
            Console.WriteLine($"Initializing Kafka consumer with bootstrap servers: {_bootstrapServers}");
            
            // config consumer
            var kafkaConfig = new ConsumerConfig {
                BootstrapServers = _bootstrapServers,
                GroupId = "email-service-group",
                AutoOffsetReset = AutoOffsetReset.Earliest
            };
            _consumer = new ConsumerBuilder<string, string>(kafkaConfig).Build();
            _emailService = emailService;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken){
            // subcribe topic
            _consumer.Subscribe(Topic);
            Console.WriteLine("Subscribed to topic: " + Topic);
            Console.WriteLine($"Using Kafka bootstrap servers: {_bootstrapServers}");
            
            while (!stoppingToken.IsCancellationRequested) {
                try
                {
                    var consumeResult = _consumer.Consume(stoppingToken);

                    // convert JSON -> object
                    var message = JsonSerializer.Deserialize<UserRegistered>(consumeResult.Message.Value);
                    if(message != null) {
                        Console.WriteLine($"Received message: Email={message.Email}, Username={message.Username}");
                        await _emailService.SendWelcomeEmail(message.Email, message.Username);
                    }
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Error: {ex.Message}");
                }
            }
        }

        public override void Dispose()
        {
            _consumer?.Dispose();
            base.Dispose();
        }
    }

    public class UserRegistered {
        public required string Email {get; set;}
        public required string Username {get; set;}

        public DateTime Timestamp {get; set;}
    }
}