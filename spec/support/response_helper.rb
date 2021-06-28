# frozen_string_literal: true

module ResponseHelper
  def allow_filter_response
    {
      risk: 0.32,
      signals: {},
      policy: {
        action: "allow",
        name: "Allow Filter Test Policy",
        id: SecureRandom.uuid,
        revision_id: SecureRandom.uuid
      }
    }
  end

  def deny_filter_response
    {
      risk: 0.91,
      signals: {
        credentials_stuffing: {},
        datacenter_ip: {}
      },
      policy: {
        action: "deny",
        name: "Deny Filter Test Policy",
        id: SecureRandom.uuid,
        revision_id: SecureRandom.uuid
      }
    }
  end

  def allow_risk_response
    {
      risk: 0.32,
      policy: {
        action: "allow",
        id: SecureRandom.uuid,
        revision_id: SecureRandom.uuid,
        name: "Allow Risk Test Policy"
      },
      signals: {},
      device: {
        token: "eyJhbGciOiJIUzI1NiJ9.eyJ0b2tlbiI6Ik1YMWc2UFhBVFItcFFsbmZ1WHZKSlNCUUVxUlAiLCJxdWFsaWZpZXIiOiJBUUlEQ2pFek5ETTBNakl6TXpRIiwiYW5vbnltb3VzIjpmYWxzZSwidmVyc2lvbiI6MC4zfQ.CoklyimrqWRlCV6HWLhlZh2gJvEql7bt11VRknCisc8"
      }
    }
  end

  def challenge_risk_response
    {
      risk: 0.66,
      policy: {
        action: "challenge",
        id: SecureRandom.uuid,
        revision_id: SecureRandom.uuid,
        name: "Challenge Risk Test Policy"
      },
      signals: {
        unapproved_country: {},
        unapproved_os: {},
        unapproved_device: {}
      },
      device: {
        token: "eyJhbGciOiJIUzI1NiJ9.eyJ0b2tlbiI6Ik1YMWc2UFhBVFItcFFsbmZ1WHZKSlNCUUVxUlAiLCJxdWFsaWZpZXIiOiJBUUlEQ2pFek5ETTBNakl6TXpRIiwiYW5vbnltb3VzIjpmYWxzZSwidmVyc2lvbiI6MC4zfQ.CoklyimrqWRlCV6HWLhlZh2gJvEql7bt11VRknCisc8"
      }
    }
  end

  def deny_risk_response
    {
      risk: 0.99,
      policy: {
        action: "deny",
        id: SecureRandom.uuid,
        revision_id: SecureRandom.uuid,
        name: "Deny Risk Test Policy"
      },
      signals: {
        credential_stuffing: {},
        datacenter_access: {},
        generated_email: {}
      },
      device: {
        token: "eyJhbGciOiJIUzI1NiJ9.eyJ0b2tlbiI6Ik1YMWc2UFhBVFItcFFsbmZ1WHZKSlNCUUVxUlAiLCJxdWFsaWZpZXIiOiJBUUlEQ2pFek5ETTBNakl6TXpRIiwiYW5vbnltb3VzIjpmYWxzZSwidmVyc2lvbiI6MC4zfQ.CoklyimrqWRlCV6HWLhlZh2gJvEql7bt11VRknCisc8"
      }
    }
  end
end
