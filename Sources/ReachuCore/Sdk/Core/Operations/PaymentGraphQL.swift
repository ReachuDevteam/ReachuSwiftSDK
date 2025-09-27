import Foundation

public enum PaymentGraphQL {
  public static let GET_AVAILABLE_METHODS_PAYMENT_QUERY = #"""
    query GetAvailablePaymentMethods {
      Payment {
        GetAvailablePaymentMethods {
          name
        }
      }
    }
    """#

  public static let STRIPE_INTENT_PAYMENT_MUTATION = #"""
    mutation CreatePaymentIntentStripe($checkoutId: String!, $returnEphemeralKey: Boolean) {
      Payment {
        CreatePaymentIntentStripe(
          checkout_id: $checkoutId
          return_ephemeral_key: $returnEphemeralKey
        ) {
          client_secret
          customer
          publishable_key
          ephemeral_key
        }
      }
    }
    """#

  public static let STRIPE_PLATFORM_BUILDER_PAYMENT_MUTATION = #"""
    mutation CreatePaymentStripe(
      $checkoutId: String!
      $successUrl: String!
      $paymentMethod: String!
      $email: String!
    ) {
      Payment {
        CreatePaymentStripe(
          checkout_id: $checkoutId
          success_url: $successUrl
          payment_method: $paymentMethod
          email: $email
        ) {
          checkout_url
          order_id
        }
      }
    }
    """#

  public static let KLARNA_PLATFORM_BUILDER_PAYMENT_MUTATION = #"""
    mutation Payment($checkoutId: String!, $countryCode: String!, $href: String!, $email: String!) {
      Payment {
        CreatePaymentKlarna(
          checkout_id: $checkoutId
          country_code: $countryCode
          href: $href
          email: $email
        ) {
          order_id
          status
          locale
          html_snippet
        }
      }
    }
    """#

  public static let VIPPS_PAYMENT = #"""
    mutation CreatePaymentVipps($checkoutId: String!, $email: String!, $returnUrl: String!) {
      Payment {
        CreatePaymentVipps(checkout_id: $checkoutId, email: $email, return_url: $returnUrl) {
          payment_url
        }
      }
    }
    """#
}
