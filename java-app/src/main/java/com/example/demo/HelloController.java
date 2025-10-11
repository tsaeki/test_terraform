package com.example.demo;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import java.lang.management.ManagementFactory;
import java.lang.management.MemoryMXBean;
import java.util.HashMap;
import java.util.Map;

@RestController
public class HelloController {
    
    @GetMapping("/")
    public Map<String, String> hello() {
        Map<String, String> response = new HashMap<>();
        response.put("message", "Hello from Java Application with JMX!");
        response.put("status", "running");
        return response;
    }
    
    @GetMapping("/health")
    public Map<String, Object> health() {
        Map<String, Object> response = new HashMap<>();
        MemoryMXBean memoryBean = ManagementFactory.getMemoryMXBean();
        
        response.put("status", "UP");
        response.put("timestamp", System.currentTimeMillis());
        response.put("heapMemoryUsage", memoryBean.getHeapMemoryUsage().toString());
        response.put("nonHeapMemoryUsage", memoryBean.getNonHeapMemoryUsage().toString());
        
        return response;
    }
    
    @GetMapping("/metrics")
    public Map<String, Object> metrics() {
        Map<String, Object> response = new HashMap<>();
        Runtime runtime = Runtime.getRuntime();
        
        response.put("totalMemory", runtime.totalMemory());
        response.put("freeMemory", runtime.freeMemory());
        response.put("usedMemory", runtime.totalMemory() - runtime.freeMemory());
        response.put("maxMemory", runtime.maxMemory());
        response.put("availableProcessors", runtime.availableProcessors());
        
        return response;
    }
}
