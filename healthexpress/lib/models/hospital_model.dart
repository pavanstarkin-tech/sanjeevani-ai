class HospitalDepartment {
  final String id;
  final String name;
  final String? description;
  final String? headDoctor;

  HospitalDepartment({
    required this.id,
    required this.name,
    this.description,
    this.headDoctor,
  });
}

class HospitalFacility {
  final int totalBeds;
  final int icuBeds;
  final int emergencyBeds;
  final int operationTheatres;
  final bool hasPharmacy;
  final bool hasLaboratory;
  final bool hasImaging;
  final bool hasAmbulance;
  final bool hasBloodBank;
  final bool hasParking;
  final bool isWheelchairAccessible;

  HospitalFacility({
    this.totalBeds = 500,
    this.icuBeds = 60,
    this.emergencyBeds = 30,
    this.operationTheatres = 12,
    this.hasPharmacy = true,
    this.hasLaboratory = true,
    this.hasImaging = true,
    this.hasAmbulance = true,
    this.hasBloodBank = true,
    this.hasParking = true,
    this.isWheelchairAccessible = true,
  });
}

class HospitalModel {
  final String id;
  final String name;
  final String logoUrl;
  final String bannerUrl;
  final String hospitalType; // Super Specialty, Multi Specialty, Clinic
  final String licenseNumber;
  final String verificationStatus; // Verified, Pending
  final int establishedYear;
  final String location;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final double latitude;
  final double longitude;
  final double rating;
  final int reviewCount;
  final double distanceKm;
  final bool is24x7;
  final int doctorCount;
  final int specialtyCount;
  final int bedCount;
  final List<String> departments;
  final List<String> services; // Emergency, OPD, ICU, Pharmacy, Lab, Ambulance, Teleconsultation
  final List<String> facilities;
  final HospitalFacility? facilityDetails;
  final String phone;
  final String emergencyPhone;
  final String email;
  final String website;
  final String description;
  final String workingHours;

  HospitalModel({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.bannerUrl,
    this.hospitalType = 'Super Specialty Hospital',
    this.licenseNumber = 'TS-HYD-MED-2015-9921',
    this.verificationStatus = 'Verified',
    this.establishedYear = 1995,
    required this.location,
    required this.address,
    this.city = 'Hyderabad',
    this.state = 'Telangana',
    this.pincode = '500081',
    this.latitude = 17.4375,
    this.longitude = 78.4482,
    required this.rating,
    required this.reviewCount,
    required this.distanceKm,
    this.is24x7 = true,
    required this.doctorCount,
    required this.specialtyCount,
    required this.bedCount,
    required this.departments,
    this.services = const [
      '24/7 Emergency & Trauma',
      'OPD & IPD',
      'Intensive Care Unit (ICU)',
      '24/7 Pharmacy',
      'Diagnostic Pathology Lab',
      'Advanced Radiology (MRI/CT)',
      'Cardiac Catheterization Lab',
      'Ambulance Services',
      'Blood Bank',
      'Teleconsultation',
      'Home-Care Services'
    ],
    required this.facilities,
    this.facilityDetails,
    required this.phone,
    required this.emergencyPhone,
    this.email = 'info@kims.in',
    this.website = 'https://www.kimshospitals.com',
    required this.description,
    this.workingHours = '24/7 Emergency & 08:00 AM - 09:00 PM OPD',
  });
}
