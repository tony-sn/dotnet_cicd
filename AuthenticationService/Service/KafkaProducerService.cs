using System.Text.Json;
using Confluent.Kafka;
using Microsoft.Extensions.Configuration;

namespace AuthenticationService.Service {
    public class KafkaProducerService {
        private readonly IProducer<string, string> _producer;
        private const string Topic = "user-registered";
        private readonly string _bootstrapServers;

        public KafkaProducerService(IConfiguration config) {
            _bootstrapServers = config["Kafka:BootstrapServers"] ?? "kafka:9092";
            
            Console.WriteLine($"Initializing Kafka producer with bootstrap servers: {_bootstrapServers}");
            
            var kafkaConfig = new ProducerConfig{
                BootstrapServers = _bootstrapServers
            };

            _producer = new ProducerBuilder<string, string>(kafkaConfig).Build();
        }

        // viết hàm để send event tới Kafka message broker
        public async Task PublishUserRegisteredEvent(string email, string username) {
            try {
                // define new message
                var message = new {
                    Email = email,
                    Username = username,
                    Timestamp = DateTime.UtcNow
                };

                // convert về dạng JSON
                var jsonMessage = JsonSerializer.Serialize(message);

                Console.WriteLine($"Attempting to send message to Kafka topic '{Topic}' using servers: {_bootstrapServers}");
                
                // gửi message tới Kafka
                await _producer.ProduceAsync(Topic, new Message<string, string>{
                    Key = email,
                    Value = jsonMessage
                });
                
                Console.WriteLine($"Successfully sent message to Kafka topic '{Topic}'");
            }
            catch (Exception ex) {
                Console.WriteLine($"Error sending message to Kafka: {ex.Message}");
                throw;
            }
        }

        // viết hàm để close producer, clear bộ nhớ
        public void Dispose() {
            _producer.Dispose();
        }
    }
}