import '../models/offline_medical_models.dart';

/// Repository of medically validated first-aid protocols aligned with
/// WHO, International Red Cross, and AHA 2025/2026 resuscitation standards.
class ValidatedFirstAidProtocols {
  static const List<FirstAidProtocol> protocols = [
    // 1. CPR / Cardiac Arrest
    FirstAidProtocol(
      id: 'cpr_cardiac_arrest',
      title: 'Adult CPR (Cardiopulmonary Resuscitation)',
      subtitle: 'Unresponsive patient, absent breathing or abnormal gasping',
      emergencyLevel: EmergencyTriageLevel.critical,
      validatedBy: 'AHA / ERC 2025 Resuscitation Guidelines',
      iconCode: 'favorite',
      keywords: ['cpr', 'cardiac', 'unconscious', 'chest compression', 'heart stop', 'pulse', 'gasping', 'collapse'],
      quickSummary: 'Call 108/112 immediately. Begin continuous firm chest compressions at 100-120 BPM in center of chest.',
      steps: [
        FirstAidStep(
          stepNumber: 1,
          title: 'Assess Responsiveness & Call 108 / 112',
          detail: 'Tap shoulders firmly and shout: "Are you okay?". Check chest for breathing for no more than 10 seconds. If unresponsive and not breathing normally, call emergency services immediately or direct a bystander.',
          warning: 'Do not delay compressions for pulse checks if untrained.',
          audioInstruction: 'Tap shoulders firmly. If no response, call 108 immediately and begin chest compressions.',
        ),
        FirstAidStep(
          stepNumber: 2,
          title: 'Position Hands on Center of Chest',
          detail: 'Place the heel of one hand on the lower half of patient\'s breastbone (sternum). Place your other hand on top and interlock fingers. Keep elbows locked straight and position shoulders directly above hands.',
          audioInstruction: 'Place the heel of your hand on the center of the chest. Interlock fingers and lock elbows straight.',
        ),
        FirstAidStep(
          stepNumber: 3,
          title: 'Deliver High-Quality Compressions (100-120 BPM)',
          detail: 'Compress chest at least 2 inches (5 to 6 cm) deep at a cadence of 100 to 120 beats per minute. Allow complete chest recoil between each push. For hands-only CPR, do continuous compressions until paramedics arrive.',
          hasMetronome: true,
          metronomeBpm: 110,
          timerSeconds: 120,
          audioInstruction: 'Push hard and fast to the beat. Push down 2 inches deep and allow chest to rise fully.',
        ),
        FirstAidStep(
          stepNumber: 4,
          title: 'AED (Defibrillator) Deployment',
          detail: 'If an Automated External Defibrillator (AED) is available, turn it on immediately and adhere pads to patient\'s bare chest as shown on AED diagrams. Follow AED voice prompts.',
          audioInstruction: 'If an AED arrives, open it, attach pads to bare chest, and obey its voice prompts.',
        ),
      ],
      dos: [
        'Push down 5-6 cm hard and fast.',
        'Allow full chest recoil between compressions.',
        'Rotate with another rescuer every 2 minutes to prevent fatigue.',
      ],
      donts: [
        'Do not bend your elbows while compressing.',
        'Do not interrupt chest compressions for more than 10 seconds.',
        'Do not give rescue breaths if not trained; hands-only CPR saves lives.',
      ],
      redFlags: [
        'Unconscious patient.',
        'Agonal gasping or absent respiration.',
        'Cyanosis (blue/purple lips or fingernails).',
      ],
    ),

    // 2. Choking / Heimlich Maneuver
    FirstAidProtocol(
      id: 'choking_heimlich',
      title: 'Choking & Airway Obstruction (Heimlich)',
      subtitle: 'Inability to speak, cough, or breathe; universal choking sign',
      emergencyLevel: EmergencyTriageLevel.critical,
      validatedBy: 'International Red Cross Guidelines',
      iconCode: 'air',
      keywords: ['choking', 'heimlich', 'throat', 'cannot breathe', 'food stuck', 'swallowed', 'cough'],
      quickSummary: 'Deliver 5 sharp back blows between shoulder blades followed by 5 abdominal thrusts (Heimlich maneuver).',
      steps: [
        FirstAidStep(
          stepNumber: 1,
          title: 'Confirm Severe Choking',
          detail: 'Ask "Are you choking?". If the person can cough forcefully or speak, encourage them to cough. If they cannot speak, nod, or are clutching their throat, intervene immediately.',
          audioInstruction: 'Ask if they are choking. If they cannot speak or cough, stand behind them immediately.',
        ),
        FirstAidStep(
          stepNumber: 2,
          title: '5 Sharp Back Blows',
          detail: 'Stand to the side and slightly behind. Support the victim\'s chest with one hand and lean them forward. Deliver 5 sharp blows between shoulder blades with the heel of your other hand.',
          audioInstruction: 'Lean the patient forward and deliver five firm back blows between shoulder blades.',
        ),
        FirstAidStep(
          stepNumber: 3,
          title: '5 Abdominal Thrusts (Heimlich Maneuver)',
          detail: 'Stand behind the person. Place a fist thumb-side in just above their navel (well below ribcage). Grasp the fist with your other hand. Pull sharply inwards and upwards.',
          audioInstruction: 'Make a fist above the navel. Pull inward and upward in quick, sharp thrusts.',
        ),
        FirstAidStep(
          stepNumber: 4,
          title: 'Repeat & Unconscious Protocol',
          detail: 'Alternate between 5 back blows and 5 abdominal thrusts until object is expelled. If victim loses consciousness, lower them gently to floor and begin CPR immediately.',
          warning: 'Never perform blind finger sweeps in the mouth as this can push object deeper.',
          audioInstruction: 'Repeat 5 blows and 5 thrusts. If person loses consciousness, immediately start CPR.',
        ),
      ],
      dos: [
        'Lean victim forward so object falls out rather than down airway.',
        'Call 108/112 if object does not clear within 30 seconds.',
        'Use chest thrusts (not abdominal) for pregnant women or obese individuals.',
      ],
      donts: [
        'Do not slap the back if the person is coughing forcefully.',
        'Do not stick fingers blindly down the throat.',
        'Do not offer water while someone is actively choking.',
      ],
      redFlags: [
        'Turning blue or pale.',
        'Silent struggling with clutching throat.',
        'Loss of consciousness.',
      ],
    ),

    // 3. Severe Bleeding / Hemorrhage
    FirstAidProtocol(
      id: 'severe_bleeding',
      title: 'Severe Bleeding & Hemorrhage Control',
      subtitle: 'Spurting or continuous arterial/venous blood flow from wounds',
      emergencyLevel: EmergencyTriageLevel.critical,
      validatedBy: 'Stop the Bleed & WHO Trauma Guidelines',
      iconCode: 'water_drop',
      keywords: ['bleeding', 'blood', 'cut', 'wound', 'hemorrhage', 'tourniquet', 'gash', 'artery'],
      quickSummary: 'Apply direct, firm pressure with sterile dressing. Elevate limb if possible. Apply tourniquet if limb bleeding is uncontrollable.',
      steps: [
        FirstAidStep(
          stepNumber: 1,
          title: 'Direct Firm Pressure',
          detail: 'Cover wound with clean cloth or sterile gauze. Press down firmly with both hands directly over the site of bleeding. Maintain continuous pressure for at least 5 to 10 minutes without lifting cloth to check.',
          audioInstruction: 'Press down hard on the wound with a clean cloth. Do not lift the cloth to check.',
        ),
        FirstAidStep(
          stepNumber: 2,
          title: 'Add Dressings (Do Not Remove)',
          detail: 'If blood seeps through, do NOT remove the original dressing. Place additional gauze or cloth on top and continue pressing hard. Removing dressing dislodges vital clotting factors.',
          audioInstruction: 'If blood soaks through, add more cloth on top. Never peel off the bottom dressing.',
        ),
        FirstAidStep(
          stepNumber: 3,
          title: 'Tourniquet Application (For Severe Limb Arterial Bleeding)',
          detail: 'If bleeding from arm or leg is spurting or uncontrollable with direct pressure, place a commercial tourniquet or wide strap 2-3 inches above the wound (not over a joint). Tighten until bleeding stops. Record exact time applied.',
          warning: 'Do not loosen tourniquet once applied. Note the exact application time on forehead or strap.',
          audioInstruction: 'Apply a tight band two to three inches above the wound on the arm or leg until bleeding stops.',
        ),
        FirstAidStep(
          stepNumber: 4,
          title: 'Prevent Hypothermia & Shock',
          detail: 'Keep the patient lying down, elevate legs 12 inches if no spinal or pelvic injury is suspected, and cover with a blanket to keep warm.',
          audioInstruction: 'Keep the patient lying down and warm to prevent clinical shock.',
        ),
      ],
      dos: [
        'Maintain continuous direct pressure for at least 10 minutes.',
        'Keep patient calm, lying down, and warm.',
        'Call 108/112 immediately for spurting blood or deep lacerations.',
      ],
      donts: [
        'Do not remove embedded objects (knife, glass) — stabilize around them.',
        'Do not wash deep, heavily bleeding wounds under tap.',
        'Do not release a tourniquet once secured.',
      ],
      redFlags: [
        'Pulsing or spurting blood.',
        'Patient exhibits cold clammy skin, rapid pulse, dizziness (hypovolemic shock).',
        'Bleeding does not slow after 10 minutes of direct pressure.',
      ],
    ),

    // 4. Burns & Scalds
    FirstAidProtocol(
      id: 'burns_and_scalds',
      title: 'Thermal Burns & Scalds Management',
      subtitle: 'Heat, flame, hot liquid, or steam exposure to skin',
      emergencyLevel: EmergencyTriageLevel.urgent,
      validatedBy: 'British Burn Association & WHO Burns Care',
      iconCode: 'local_fire_department',
      keywords: ['burn', 'scald', 'fire', 'hot water', 'steam', 'boiling', 'skin burn', 'blister'],
      quickSummary: 'Cool burn under cool running tap water for 20 minutes. Remove jewelry/loose clothing. Cover loosely with cling wrap or sterile dressing.',
      steps: [
        FirstAidStep(
          stepNumber: 1,
          title: 'Cool with Running Water for 20 Minutes',
          detail: 'Immediately place burn under gentle, cool running tap water for 20 full minutes. This cools underlying dermis, stops progressive tissue cooking, and provides immense pain relief.',
          timerSeconds: 1200,
          warning: 'Do NOT use ice, iced water, butter, toothpaste, or turmeric. Ice causes vasoconstriction and severe thermal ischemia.',
          audioInstruction: 'Cool the burn under running cool tap water for 20 continuous minutes. Do not use ice.',
        ),
        FirstAidStep(
          stepNumber: 2,
          title: 'Remove Constricting Items',
          detail: 'Gently remove rings, watches, belts, and loose clothing before swelling develops. However, do NOT pull off clothing that is melted or stuck to the burn wound.',
          audioInstruction: 'Remove rings and watches near the burn before swelling begins. Do not peel stuck clothes.',
        ),
        FirstAidStep(
          stepNumber: 3,
          title: 'Protect with Clean Cover or Cling Wrap',
          detail: 'Cover the cooled burn loosely with clear plastic food wrap (cling film) or a clean, non-adherent sterile dressing. Lay the wrap flat; do not wrap tightly around a limb.',
          audioInstruction: 'Cover the burn loosely with clean plastic cling wrap or sterile gauze.',
        ),
        FirstAidStep(
          stepNumber: 4,
          title: 'Pain Relief & Medical Triage',
          detail: 'Seek urgent hospital care if burn is larger than the victim\'s palm, involves face, hands, feet, groin, or major joints, or exhibits charred white or leathery skin (third-degree).',
          audioInstruction: 'If the burn is large or on face, hands, or joints, go to hospital emergency.',
        ),
      ],
      dos: [
        'Cool under cool tap water for 20 full minutes.',
        'Keep patient warm elsewhere to prevent hypothermia.',
        'Seek emergency care for chemical, electrical, or full-thickness burns.',
      ],
      donts: [
        'Never pop or puncture blisters.',
        'Never apply toothpaste, butter, oil, cow dung, or raw eggs.',
        'Never apply ice directly to burned skin.',
      ],
      redFlags: [
        'Burns exceeding 3% of body surface (size of 3 palms).',
        'Burns to face, airway (singed nasal hairs, soot in mouth), genitals, or hands.',
        'Painless white or charred leathery skin (full thickness burn).',
      ],
    ),

    // 5. Snake Bite
    FirstAidProtocol(
      id: 'snake_bite',
      title: 'Snake Bite & Envenomation Protocol',
      subtitle: 'Venomous snake bite with fang marks, swelling, or pain',
      emergencyLevel: EmergencyTriageLevel.critical,
      validatedBy: 'WHO Guidelines for Prevention and Clinical Management of Snakebite',
      iconCode: 'pest_control',
      keywords: ['snake', 'bite', 'fang', 'venom', 'cobra', 'viper', 'krait', 'reptile'],
      quickSummary: 'Keep victim calm and completely still. Immobilize the bitten limb below heart level. Transport immediately to hospital with Anti-Snake Venom (ASV).',
      steps: [
        FirstAidStep(
          stepNumber: 1,
          title: 'Immobilize the Patient & Limb',
          detail: 'Instruct the victim to remain completely still. Any movement or walking pumps venom through the lymphatic system into circulation. Splint or sling the affected arm or leg.',
          audioInstruction: 'Keep the patient completely calm and still. Movement accelerates venom spread.',
        ),
        FirstAidStep(
          stepNumber: 2,
          title: 'Position Below Heart Level',
          detail: 'Keep the bitten limb below the level of the patient\'s heart. Remove rings, bangles, anklets, and shoes before regional swelling expands.',
          audioInstruction: 'Keep the bitten limb positioned below the heart and remove all rings or tight items.',
        ),
        FirstAidStep(
          stepNumber: 3,
          title: 'Pressure Immobilization Bandage (If Elapid / Neurotoxic)',
          detail: 'Apply a broad elastic compression bandage from digits up towards torso with moderate firmness (like an ankle sprain). Do NOT cut off arterial blood supply.',
          warning: 'DO NOT cut, suction, apply tourniquet, herbal paste, or electroshock.',
          audioInstruction: 'Wrap with a firm bandage if available, but never apply a tight tourniquet.',
        ),
        FirstAidStep(
          stepNumber: 4,
          title: 'Urgent Transport to Nearest Hospital with ASV',
          detail: 'Arrange immediate vehicle transport (do not let patient walk). Call ahead to ensure hospital stocks polyvalent Anti-Snake Venom (ASV). Note snake description if safe to do so.',
          audioInstruction: 'Transport immediately by vehicle to the nearest hospital stocking anti-snake venom.',
        ),
      ],
      dos: [
        'Keep patient calm, reassuring them that most bites are treatable.',
        'Immobilize limb with a makeshift splint.',
        'Take a photo of snake from a safe distance if possible.',
      ],
      donts: [
        'Do not cut the bite mark or try to suck out venom.',
        'Do not apply a tight arterial tourniquet.',
        'Do not apply ice, potassium permanganate, or herbal remedies.',
        'Do not give alcohol or pain medication before clinical assessment.',
      ],
      redFlags: [
        'Drooping eyelids (ptosis), slurred speech, or difficulty swallowing (neurotoxin).',
        'Bleeding from gums, nose, or puncture site (hemotoxin).',
        'Rapid swelling traveling up the limb.',
      ],
    ),

    // 6. Heart Attack / Acute Chest Pain
    FirstAidProtocol(
      id: 'heart_attack_chest_pain',
      title: 'Suspected Heart Attack (Acute Coronary Syndrome)',
      subtitle: 'Pressure, tightness, or pain in chest radiating to arm, neck, or jaw',
      emergencyLevel: EmergencyTriageLevel.critical,
      validatedBy: 'AHA & ESC Acute Cardiac Care Guidelines',
      iconCode: 'monitor_heart',
      keywords: ['heart attack', 'chest pain', 'angina', 'cardiac', 'left arm pain', 'jaw pain', 'sweating', 'breathless'],
      quickSummary: 'Call 108 immediately. Have patient sit in comfortable "W" position. Administer 300mg chewable aspirin if not allergic.',
      steps: [
        FirstAidStep(
          stepNumber: 1,
          title: 'Call Emergency Services (108 / 112)',
          detail: 'Call for an advanced cardiac ambulance immediately. Every minute saved preserves cardiac muscle.',
          audioInstruction: 'Call emergency ambulance 108 immediately. State suspected heart attack.',
        ),
        FirstAidStep(
          stepNumber: 2,
          title: 'Rest in Comfortable "W" Sitting Position',
          detail: 'Help patient sit on the floor leaning against a wall or chair with knees bent and head supported. This reduces workload on heart and helps ease breathing.',
          audioInstruction: 'Help the patient sit half-upright with knees bent to reduce strain on the heart.',
        ),
        FirstAidStep(
          stepNumber: 3,
          title: 'Administer Aspirin (If Eligible)',
          detail: 'If the patient is conscious, has NO known allergy to aspirin, and has no active gastrointestinal bleeding, give 300 mg of soluble or chewable aspirin to chew and swallow with minimal water.',
          warning: 'Do not give aspirin if patient has known aspirin allergy or active internal bleeding.',
          audioInstruction: 'Have the patient chew one 300mg aspirin tablet if they are not allergic.',
        ),
        FirstAidStep(
          stepNumber: 4,
          title: 'Assist with Prescribed Nitroglycerin (GTN)',
          detail: 'If the patient has prescribed sublingual nitroglycerin tablets or spray for angina, assist them in taking one dose under the tongue while seated.',
          audioInstruction: 'If patient has prescribed nitroglycerin spray or tablet, assist them in taking it.',
        ),
      ],
      dos: [
        'Keep patient calm, seated, and still.',
        'Loosen tight collar, tie, or belt.',
        'Be prepared to begin CPR immediately if patient becomes unresponsive.',
      ],
      donts: [
        'Do not let patient walk or exert themselves.',
        'Do not give aspirin if allergic or history of bleeding ulcers.',
        'Do not dismiss chest discomfort as simple indigestion or acidity.',
      ],
      redFlags: [
        'Crushing chest pressure lasting more than 5 minutes.',
        'Pain radiating down left arm, jaw, neck, or back.',
        'Profuse cold sweating, nausea, shortness of breath.',
      ],
    ),

    // 7. Seizures & Convulsions
    FirstAidProtocol(
      id: 'seizure_epilepsy',
      title: 'Seizures & Convulsion Management',
      subtitle: 'Sudden uncontrollable shaking, loss of consciousness, or spasms',
      emergencyLevel: EmergencyTriageLevel.urgent,
      validatedBy: 'International League Against Epilepsy (ILAE) Protocol',
      iconCode: 'bolt',
      keywords: ['seizure', 'fits', 'convulsion', 'epilepsy', 'shaking', 'frothing', 'jerking'],
      quickSummary: 'Protect head, clear dangerous objects, time the seizure. Turn to recovery position after shaking stops. DO NOT put anything in mouth.',
      steps: [
        FirstAidStep(
          stepNumber: 1,
          title: 'Protect From Physical Trauma',
          detail: 'Gently guide them away from hazards. Place a soft cushion, rolled jacket, or folded towel under their head. Clear nearby sharp, hard, or hot objects.',
          audioInstruction: 'Protect their head with a soft jacket or pillow. Clear away hard or sharp objects.',
        ),
        FirstAidStep(
          stepNumber: 2,
          title: 'Time the Seizure Duration',
          detail: 'Note the exact time seizure began on your watch or phone. If convulsions continue for more than 5 minutes, call 108 immediately (Status Epilepticus).',
          timerSeconds: 300,
          audioInstruction: 'Start a timer. If shaking lasts longer than 5 minutes, call an ambulance immediately.',
        ),
        FirstAidStep(
          stepNumber: 3,
          title: 'Do NOT Restrain or Insert Objects',
          detail: 'Do NOT hold the person down or try to stop their jerking. NEVER place fingers, spoons, coins, or cloth inside their mouth. People cannot swallow their tongue.',
          warning: 'Inserting objects can break teeth, cause airway obstruction, or bite severing.',
          audioInstruction: 'Do not hold them down and never put anything into their mouth.',
        ),
        FirstAidStep(
          stepNumber: 4,
          title: 'Roll into Recovery Position After Convulsions Stop',
          detail: 'Once jerking ceases, turn the person onto their side (recovery position) with chin tilted slightly upward to keep the airway open and allow saliva or vomit to drain safely.',
          audioInstruction: 'When shaking stops, gently turn the person onto their side to keep airway clear.',
        ),
      ],
      dos: [
        'Cushion the head and loosen neckwear.',
        'Roll into side recovery position once jerking stops.',
        'Stay with the person until fully alert and oriented.',
      ],
      donts: [
        'Never put spoons, keys, or fingers in their mouth.',
        'Never restrain or pin their limbs down.',
        'Never make them smell onions, leather, or shoes.',
        'Never offer water until they are completely awake.',
      ],
      redFlags: [
        'Seizure lasts longer than 5 minutes.',
        'Second seizure occurs without regaining consciousness.',
        'Seizure occurs in water or pregnant female.',
      ],
    ),

    // 8. Bone Fractures & Sprains
    FirstAidProtocol(
      id: 'bone_fracture_sprain',
      title: 'Bone Fractures & Joint Dislocations',
      subtitle: 'Visible bone deformity, intense localized pain, inability to bear weight',
      emergencyLevel: EmergencyTriageLevel.urgent,
      validatedBy: 'American Academy of Orthopaedic Surgeons (AAOS)',
      iconCode: 'broken_image',
      keywords: ['fracture', 'broken bone', 'dislocation', 'sprain', 'bone crack', 'swollen leg', 'twisted ankle'],
      quickSummary: 'Immobilize the joint above and below injury. Apply ice wrapped in cloth. Never attempt to realign deformed bones.',
      steps: [
        FirstAidStep(
          stepNumber: 1,
          title: 'Immobilize in Found Position',
          detail: 'Do not move the injured body part. Stabilize the injured limb in the exact position it was found using pillows, folded blankets, or cardboard splints.',
          audioInstruction: 'Keep the injured limb completely still in the position it was found.',
        ),
        FirstAidStep(
          stepNumber: 2,
          title: 'Splint Above and Below Injury',
          detail: 'Secure a rigid splint (cardboard, wood, folded magazine) extending across the joint above and the joint below the suspected fracture using bandages or cloth strips.',
          warning: 'Never attempt to push protruding bone ends back beneath the skin.',
          audioInstruction: 'Support the bone with a splint extending beyond the joints on both sides.',
        ),
        FirstAidStep(
          stepNumber: 3,
          title: 'Cold Pack Application',
          detail: 'Apply an ice pack wrapped in a cloth or towel to reduce swelling and pain for 15-20 minutes at a time. Never place ice directly on bare skin.',
          audioInstruction: 'Apply a cold pack wrapped in cloth to reduce swelling and ease pain.',
        ),
        FirstAidStep(
          stepNumber: 4,
          title: 'Check Distal Circulation (PMS)',
          detail: 'Check Pulse, Motor function, and Sensory feeling beyond the injury (e.g., wiggle toes or fingers). If fingers/toes turn pale, blue, cold, or numb, loosen splint immediately.',
          audioInstruction: 'Check that fingers or toes have normal feeling, warmth, and blood flow.',
        ),
      ],
      dos: [
        'Support limb gently with rolled clothing or splint.',
        'Check that fingers/toes stay warm and have pulse.',
        'Control any open wound bleeding with clean dressing.',
      ],
      donts: [
        'Do not try to straighten or push crooked bones back.',
        'Do not massage the broken or swollen limb.',
        'Do not allow patient to walk or put weight on injured limb.',
      ],
      redFlags: [
        'Bone piercing through skin (compound open fracture).',
        'Cold, pale, or blue hand/foot with lost pulses.',
        'Suspected spine, neck, or pelvic fracture.',
      ],
    ),

    // 9. Heat Stroke & Hyperthermia
    FirstAidProtocol(
      id: 'heat_stroke',
      title: 'Heat Stroke & Severe Heat Exhaustion',
      subtitle: 'Body temperature > 40°C (104°F), confusion, hot dry skin or cessation of sweat',
      emergencyLevel: EmergencyTriageLevel.critical,
      validatedBy: 'Wilderness Medical Society & WHO Climate Health Protocols',
      iconCode: 'thermostat',
      keywords: ['heat stroke', 'heat exhaustion', 'sunstroke', 'hot skin', 'delirium', 'hyperthermia'],
      quickSummary: 'Move to shade immediately. Rapidly cool body with cold water mist and fan. Place ice packs on neck, armpits, and groin.',
      steps: [
        FirstAidStep(
          stepNumber: 1,
          title: 'Move to Cool Environment',
          detail: 'Immediately transport victim out of direct sunlight into air-conditioned room or deep shade. Remove unnecessary outer layers of clothing.',
          audioInstruction: 'Move the person to cool shade or air conditioning and remove heavy clothing.',
        ),
        FirstAidStep(
          stepNumber: 2,
          title: 'Rapid Evaporative Cooling',
          detail: 'Spray or sponge patient\'s entire body with cool water while vigorously fanning them. Evaporation rapidly extracts body heat.',
          audioInstruction: 'Spray cool water over their body and fan continuously to bring temperature down.',
        ),
        FirstAidStep(
          stepNumber: 3,
          title: 'Targeted Ice Pack Placement',
          detail: 'Place ice packs or cold wet towels over areas with high blood flow: neck, under armpits, and groin.',
          audioInstruction: 'Place ice packs or wet cold towels on neck, armpits, and groin.',
        ),
        FirstAidStep(
          stepNumber: 4,
          title: 'Hydration Guidelines',
          detail: 'If conscious and able to swallow, provide cool water or oral rehydration salts (ORS) in small sips. If patient is confused, drowsy, or vomiting, do NOT force fluids by mouth.',
          warning: 'Do not give aspirin or paracetamol for environmental heat stroke; it does not reduce core environmental temperature and stresses liver.',
          audioInstruction: 'Give small sips of water only if fully awake. Never force fluids if drowsy.',
        ),
      ],
      dos: [
        'Begin aggressive cooling immediately before and during ambulance transit.',
        'Fan continuously over wet skin.',
        'Keep airway open if consciousness alters.',
      ],
      donts: [
        'Do not give paracetamol or aspirin for heat stroke.',
        'Do not give ice-cold water to drink quickly (causes stomach spasms).',
        'Do not leave the patient unattended.',
      ],
      redFlags: [
        'Confusion, delirium, or combativeness.',
        'Hot, flushed, dry skin with no sweating.',
        'Loss of consciousness or seizures.',
      ],
    ),

    // 10. Asthma Attack & Acute Bronchospasm
    FirstAidProtocol(
      id: 'asthma_attack',
      title: 'Severe Asthma Attack & Bronchospasm',
      subtitle: 'Severe wheezing, tight chest, unable to complete a sentence in one breath',
      emergencyLevel: EmergencyTriageLevel.critical,
      validatedBy: 'Global Initiative for Asthma (GINA) Emergency Care',
      iconCode: 'air',
      keywords: ['asthma', 'wheeze', 'inhaler', 'shortness of breath', 'salbutamol', 'bronchitis', 'breathing difficulty'],
      quickSummary: 'Sit patient upright. Administer blue reliever inhaler (Salbutamol) 4 puffs via spacer; repeat every 4 minutes if unyielding.',
      steps: [
        FirstAidStep(
          stepNumber: 1,
          title: 'Sit Upright & Reassure',
          detail: 'Have the person sit comfortably upright with back straight. Leaning slightly forward can expand thoracic capacity. Do NOT let them lie flat.',
          audioInstruction: 'Help the person sit upright leaning slightly forward. Do not let them lie down.',
        ),
        FirstAidStep(
          stepNumber: 2,
          title: 'Administer Reliever Inhaler (4 Puffs Rule)',
          detail: 'Shake blue reliever inhaler (Salbutamol/Albuterol). Administer 1 puff into spacer, instruct patient to take 4 slow deep breaths. Repeat for a total of 4 separate puffs.',
          audioInstruction: 'Shake their blue reliever inhaler. Give 4 puffs, taking 4 slow breaths after each puff.',
        ),
        FirstAidStep(
          stepNumber: 3,
          title: 'Wait 4 Minutes & Re-Evaluate',
          detail: 'Wait 4 minutes. If symptoms do not improve, deliver another 4 puffs of the reliever inhaler.',
          timerSeconds: 240,
          audioInstruction: 'Wait four minutes. If breathing is still difficult, deliver another 4 puffs.',
        ),
        FirstAidStep(
          stepNumber: 4,
          title: 'Emergency Ambulance Trigger',
          detail: 'If there is no improvement after 8 to 10 puffs, or if patient has silent chest, exhaustion, or blue lips, call 108 immediately and continue inhaler every 2 minutes.',
          audioInstruction: 'If breathing does not ease, call 108 immediately and keep giving inhaler puffs.',
        ),
      ],
      dos: [
        'Keep patient calm and seated upright.',
        'Use spacer device with inhaler whenever possible for maximum lung delivery.',
        'Call 108 promptly if unable to speak or lips turn pale/blue.',
      ],
      donts: [
        'Do not allow patient to lie flat.',
        'Do not crowd around the patient.',
        'Do not withhold extra inhaler puffs in severe distress.',
      ],
      redFlags: [
        'Unable to speak complete sentences.',
        'Silent chest (wheezing stops due to severe airflow blockage).',
        'Blue discoloration of lips or fingernails.',
      ],
    ),
  ];

  /// Find protocol matching user query or symptoms.
  static FirstAidProtocol? findProtocolForQuery(String query) {
    final q = query.toLowerCase();
    for (final p in protocols) {
      if (q.contains(p.title.toLowerCase()) || q.contains(p.id.toLowerCase())) {
        return p;
      }
      for (final kw in p.keywords) {
        if (q.contains(kw.toLowerCase())) {
          return p;
        }
      }
    }
    return null;
  }
}
