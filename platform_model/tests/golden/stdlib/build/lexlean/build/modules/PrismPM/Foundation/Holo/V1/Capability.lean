module
public import Init
set_option autoImplicit false
namespace PrismPM.Foundation.Holo.V1.Capability

public structure CapabilityRequest where
  storageRoots : List (String)
  storageQuotaBytes : UInt64
  networkFetchEndpoints : List (String)
  networkAnnounceEndpoints : List (String)
  publishChannels : List (String)
  subscribeChannels : List (String)
  memoryMaximumBytes : UInt64
  cpuMillisecondsPerEvent : UInt64
  priorityWeight : UInt32

public structure ChildDelegation where
  applicationKappa : ByteArray
  capabilitiesKappa : ByteArray

@[expose] public def emptyRequest : CapabilityRequest := ({ storageRoots := ([] : List (String)), storageQuotaBytes := (0 : UInt64), networkFetchEndpoints := ([] : List (String)), networkAnnounceEndpoints := ([] : List (String)), publishChannels := ([] : List (String)), subscribeChannels := ([] : List (String)), memoryMaximumBytes := (0 : UInt64), cpuMillisecondsPerEvent := (0 : UInt64), priorityWeight := (0 : UInt32) } : CapabilityRequest)

end PrismPM.Foundation.Holo.V1.Capability
