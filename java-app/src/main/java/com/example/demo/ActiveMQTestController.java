package com.example.demo;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jms.core.JmsTemplate;
import org.springframework.web.bind.annotation.*;
import jakarta.jms.Queue;
import jakarta.jms.Topic;
import java.util.*;

@RestController
@RequestMapping("/activemq")
public class ActiveMQTestController {
    
    @Autowired
    private JmsTemplate jmsTemplate;
    
    private List<String> receivedMessages = Collections.synchronizedList(new ArrayList<>());
    
    @PostMapping("/send/queue/{queueName}")
    public Map<String, String> sendToQueue(
            @PathVariable String queueName,
            @RequestBody Map<String, String> payload) {
        
        String message = payload.getOrDefault("message", "Test message");
        jmsTemplate.convertAndSend(queueName, message);
        
        Map<String, String> response = new HashMap<>();
        response.put("status", "success");
        response.put("queue", queueName);
        response.put("message", message);
        response.put("timestamp", String.valueOf(System.currentTimeMillis()));
        return response;
    }
    
    @PostMapping("/send/topic/{topicName}")
    public Map<String, String> sendToTopic(
            @PathVariable String topicName,
            @RequestBody Map<String, String> payload) {
        
        String message = payload.getOrDefault("message", "Test message");
        jmsTemplate.setPubSubDomain(true);
        jmsTemplate.convertAndSend(topicName, message);
        jmsTemplate.setPubSubDomain(false);
        
        Map<String, String> response = new HashMap<>();
        response.put("status", "success");
        response.put("topic", topicName);
        response.put("message", message);
        response.put("timestamp", String.valueOf(System.currentTimeMillis()));
        return response;
    }
    
    @GetMapping("/receive/queue/{queueName}")
    public Map<String, Object> receiveFromQueue(@PathVariable String queueName) {
        jmsTemplate.setReceiveTimeout(5000);
        String message = (String) jmsTemplate.receiveAndConvert(queueName);
        
        Map<String, Object> response = new HashMap<>();
        if (message != null) {
            response.put("status", "success");
            response.put("queue", queueName);
            response.put("message", message);
            response.put("timestamp", String.valueOf(System.currentTimeMillis()));
        } else {
            response.put("status", "no_message");
            response.put("queue", queueName);
            response.put("message", "No message available in queue");
        }
        return response;
    }
    
    @GetMapping("/received")
    public Map<String, Object> getReceivedMessages() {
        Map<String, Object> response = new HashMap<>();
        response.put("count", receivedMessages.size());
        response.put("messages", new ArrayList<>(receivedMessages));
        return response;
    }
    
    @DeleteMapping("/received")
    public Map<String, String> clearReceivedMessages() {
        receivedMessages.clear();
        Map<String, String> response = new HashMap<>();
        response.put("status", "cleared");
        return response;
    }
}
