//
//  ContentRules.swift
//  OnionBrowser
//
//  Created by Benjamin Erhart on 11.08.26.
//  Copyright © 2026 Tigas Ventures, LLC (Mike Tigas). All rights reserved.
//

import Foundation
import WebKit

/**
 This is used for fixing a leak in conjunction with DNS prefetching, as reported by the Mysk team, creators of Psylo:

 *dns-prefetch Leak (DNS Leak)*
 This new HTML keyword was introduced in Baseline 2025. When a website using this keyword is opened in an iOS browser, WebKit sends the DNS query of the link associated with dns-prefetch  to the system's DNS server regardless of whether the WKWebView is configured to use a proxy. This results in leaking DNS queries outside the proxy tunnel.
 The expected behavior when the WKWebView is configured to use a proxy is that all DNS queries related to loading a website are sent through the proxy tunnel. However, DNS queries triggered by the dns-prefetch keyword are sent outside the proxy tunnel. Both Psylo and Onion Browser are affected by this behavior. Safari has a feature flag to disable the dns-prefetch keyword, but it is on by default.

 This was fairly straightforward to fix. You just need to use the following WKContentRuleList rule:

	{
	   "trigger": {
		  "url-filter": ".*",
		  "resource-type": [
			 "ping"
		  ]
	   },
	   "action": {
		  "type": "block"
	   }
	}

 This rule should block all DNS prefetching. There isn’t much documentation on what the "ping" resource-type fully encompasses, but it likely targets <a ping> attributes, which are mostly used for tracking and analytics. So it’s good to block anyway.
 */
class ContentRules {

	static let id = "content-rules"

	static let shared = ContentRules()


	private(set) var ruleList: WKContentRuleList?


	private init() {
		if let url = Bundle.main.url(forResource: Self.id, withExtension: "json"),
		   let content = try? String(contentsOf: url, encoding: .utf8)
		{
			Task {
				do {
					ruleList = try await WKContentRuleListStore.default().compileContentRuleList(
						forIdentifier: Self.id, encodedContentRuleList: content)
				}
				catch {
					Log.error(for: ContentRules.self, error.localizedDescription)
				}
			}
		}
	}
}
