//
//  ValidationPublisherError.swift
//  
//
//  Created by Michael Housh on 8/27/19.
//


/**
 # ValidationPublisherError
 
 Represents the errors thrown by this package.
 
 */
public enum ValidationPublisherError: Error {
    
    /// Thrown when a `Subscription` has been cancelled or failed.
    case hasCompleted
}

