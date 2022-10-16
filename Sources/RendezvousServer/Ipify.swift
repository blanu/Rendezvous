//
//  Ipify.swift
//  
//
//  Created by Dr. Brandon Wiley on 10/16/22.
//

import Foundation

import Datable
import Net

public class Ipify
{
    static public func getPublicIP() throws -> String
    {
        guard let url = URL(string: "https://api.ipify.org/") else
        {
            throw IpifyError.badUrl
        }

        let data = try Data(contentsOf: url)

        return data.string
    }

    static public func getPublicIP() throws -> IPv4Address
    {
        let string: String = try Self.getPublicIP()

        guard let addr = IPv4Address(string) else
        {
            throw IpifyError.badIPAddress
        }

        return addr
    }
}

public enum IpifyError: Error
{
    case badUrl
    case badIPAddress
}
