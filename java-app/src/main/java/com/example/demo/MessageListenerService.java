package com.example.demo;

import org.springframework.jms.annotation.JmsListener;
import org.springframework.stereotype.Service;
import java.util.*;

@Service
public class MessageListenerService {
    
    private List<String> topicMessages = Collections.synchronizedList(new ArrayList<>());
    
    @JmsListener(destination = "test.topic", containerFactory = "topicListenerFactory")
    public void receiveTopicMessage(String message) {
        System.out.println("Received topic message: " + message);
        topicMessages.add(message);
    }
    
    public List<String> getTopicMessages() {
        return new ArrayList<>(topicMessages);
    }
    
    public void clearTopicMessages() {
        topicMessages.clear();
    }
}
