package com.vince.mygold

import com.vince.mygold.R 
import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.widget.TextView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory

class ListTileNativeAdFactory(private val context: Context) : NativeAdFactory {

    override fun createNativeAd(nativeAd: NativeAd, customOptions: MutableMap<String, Any>?): NativeAdView {
        val adView = LayoutInflater.from(context)
            .inflate(R.layout.native_ad_list_tile, null) as NativeAdView

        // Map the live headline text with a fallback string safety net
        val headlineView = adView.findViewById<TextView>(R.id.ad_headline)
        headlineView.text = nativeAd.headline ?: "Google AdMob Test Native Ad"
        adView.headlineView = headlineView

        // Map the live body text description with a fallback string safety net
        val bodyView = adView.findViewById<TextView>(R.id.ad_body)
        bodyView.text = nativeAd.body ?: "Your AdMob SDK is connected perfectly! This placeholder text displays when Google returns an empty test payload."
        bodyView.visibility = View.VISIBLE
        adView.bodyView = bodyView

        headlineView.text = nativeAd.headline ?: "Test Ad Headline"
        bodyView.text = nativeAd.body ?: "This is a sample test ad description body text."

        headlineView.visibility = View.VISIBLE
        bodyView.visibility = View.VISIBLE

        adView.headlineView = headlineView
        adView.bodyView = bodyView

        adView.setNativeAd(nativeAd)
        return adView
    }
}