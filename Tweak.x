#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static void appendToLog(NSString *msg) { (void)msg; /* logging desactive (build propre) */ }

static NSDictionary *premiumDict() {
    static NSDictionary *d = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        d = @{
            @"type":              @"premium",
            @"catalogue":         @"premium",
            @"player-license":    @"premium",
            @"financial-product": @"pr:premium,tc:0",
            @"name":              @"Spotify Premium",
            @"streaming-rules":   @"",
            @"audio-quality":     @"1",
            @"ads":               @"0",
            @"shuffle":           @"0",
            @"on-demand":         @"1",
            @"high-bitrate":      @"1",
            @"offline":           @"1",
            @"social-session-free-tier": @"0",
            @"premium-mini":      @"0",
            @"nft-disabled":      @"0",
        };
    });
    return d;
}

%hook SPTCoreProductState

// Log ALL reads to see what keys are being queried
- (id)objectForKeyedSubscript:(id)key {
    id orig = %orig;
    if ([key isKindOfClass:[NSString class]]) {
        NSString *override = premiumDict()[key];
        if (override) {
            appendToLog([NSString stringWithFormat:@"[%@] orig=%@ -> override=%@\n", key, orig ?: @"nil", override]);
            return override;
        }
    }
    return orig;
}

- (NSString *)stringForKey:(NSString *)key {
    NSString *orig = %orig;
    NSString *override = premiumDict()[key];
    if (override) {
        return override;
    }
    return orig;
}

// Hook setOverrides: to inject our premium values into the actual overrides dict
- (void)setOverrides:(id)overrides {
    NSMutableDictionary *mutated;
    if (overrides && [overrides isKindOfClass:[NSDictionary class]]) {
        mutated = [overrides mutableCopy];
    } else {
        mutated = [NSMutableDictionary dictionary];
    }
    [mutated addEntriesFromDictionary:premiumDict()];
    appendToLog([NSString stringWithFormat:@"setOverrides: injected %lu premium keys\n", (unsigned long)[premiumDict() count]]);
    %orig(mutated);
}

// Also hook setOriginalValues: to mutate at the source
- (void)setOriginalValues:(id)originalValues {
    NSMutableDictionary *mutated;
    if (originalValues && [originalValues isKindOfClass:[NSDictionary class]]) {
        mutated = [originalValues mutableCopy];
    } else {
        mutated = [NSMutableDictionary dictionary];
    }
    [mutated addEntriesFromDictionary:premiumDict()];
    appendToLog([NSString stringWithFormat:@"setOriginalValues: injected %lu premium keys\n", (unsigned long)[premiumDict() count]]);
    %orig(mutated);
}

%end

// Keep RCC mutation (proven to work for on-demand, skips, etc.)
%hook RCCFetchResponseHandler

- (void)updateProductStateFromResponse:(id)response event:(id)event {
    @try {
        id acctResp = [response valueForKey:@"accountAttributesSuccess"];
        if (acctResp) {
            NSMutableDictionary *attrs = [acctResp valueForKey:@"accountAttributes"];
            if (attrs) {
                NSDictionary *strOv = @{
                    @"type":              @"premium",
                    @"catalogue":         @"premium",
                    @"player-license":    @"premium",
                    @"financial-product": @"pr:premium,tc:0",
                    @"name":              @"Spotify Premium",
                    @"streaming-rules":   @"",
                    @"audio-quality":     @"1",
                };
                for (NSString *key in strOv) {
                    id attr = attrs[key];
                    if (attr) [attr setValue:strOv[key] forKey:@"stringValue"];
                }
                NSDictionary *boolOv = @{
                    @"ads":       @NO,
                    @"shuffle":   @NO,
                    @"on-demand": @YES,
                    @"high-bitrate": @YES,
                    @"offline":   @YES,
                };
                for (NSString *key in boolOv) {
                    id attr = attrs[key];
                    if (attr) [attr setValue:boolOv[key] forKey:@"boolValue"];
                }
            }
        }
    } @catch (NSException *e) {}
    %orig;
}

%end

// ===== v53 EXPERIMENT: force the app to NOT think it is free tier =====
// Hypothese: la page artiste en shuffle est construite par les FreeTier content
// operations, pilotees par un signal freeTierEnabled mis en cache au lancement.
// On force ce signal a NO et on force isOnDemand a YES pour la page artiste.

%hook SPTBuiltInSettingsFeatureImplementation
- (BOOL)freeTierEnabled {
    BOOL orig = %orig;
    appendToLog([NSString stringWithFormat:@"[freeTier] SPTBuiltInSettingsFeature orig=%d -> NO\n", orig]);
    return NO;
}
%end

%hook SPTCollectionPlatformTestManagerImplementation
- (BOOL)isFreeTierEnabled {
    BOOL orig = %orig;
    appendToLog([NSString stringWithFormat:@"[freeTier] SPTCollectionPlatformTestManager orig=%d -> NO\n", orig]);
    return NO;
}
%end

%hook SPTContextMenuActionsProviderImplementation
- (BOOL)freeTierEnabled {
    return NO;
}
%end

%hook SPTPremiumDestinationService
- (BOOL)freeTierEnabled {
    appendToLog([NSString stringWithFormat:@"[premTab] SPTPremiumDestinationService freeTierEnabled orig=%d -> NO\n", %orig]);
    return NO;
}
%end

%hook SPTNavigationFeatureImplementation
- (BOOL)freeTierEnabled {
    appendToLog([NSString stringWithFormat:@"[nav] freeTierEnabled orig=%d -> NO\n", %orig]);
    return NO;
}
%end

// badge: capter la source du type de compte affiche
%hook SPTEncorePremiumStatusRowSettingsModel
- (id)initWithPaymentType:(long long)pt planName:(id)pn daysLeft:(long long)dl iconColor:(id)ic {
    appendToLog([NSString stringWithFormat:@"[badge] paymentType=%lld planName=%@ daysLeft=%lld\n", pt, pn, dl]);
    return %orig;
}
%end

// v58: EeveeSpotify core -> muter le product-state de session a la SOURCE (au launch,
// avant que le signal free-tier ne se calcule). Fixe badge + tab.
static id mutateProductState(id ps) {
    @try {
        if ([ps isKindOfClass:[NSDictionary class]]) {
            // dump des paires interessantes pour trouver la clef du badge
            for (id k in ps) {
                id v = [ps objectForKey:k];
                if ([v isKindOfClass:[NSString class]]) {
                    NSString *ks = [k description], *vs = v;
                    NSString *lk = [ks lowercaseString];
                    if ([vs isEqualToString:@"free"] || [[vs lowercaseString] containsString:@"free"] ||
                        [lk containsString:@"name"] || [lk containsString:@"type"] ||
                        [lk containsString:@"catalog"] || [lk containsString:@"market"] ||
                        [lk containsString:@"product"] || [lk containsString:@"tier"] ||
                        [lk containsString:@"premium"] || [lk containsString:@"nft"]) {
                        appendToLog([NSString stringWithFormat:@"[ps] %@ = %@\n", ks, vs]);
                    }
                }
            }
            NSMutableDictionary *m = [ps mutableCopy];
            [m addEntriesFromDictionary:premiumDict()];
            return m;
        }
    } @catch (__unused NSException *e) {}
    return ps;
}

%hook SPTAuthSession
- (void)productStateUpdated:(id)ps {
    appendToLog([NSString stringWithFormat:@"[AUTH] productStateUpdated class=%@\n", NSStringFromClass([ps class])]);
    %orig(mutateProductState(ps));
}
%end

%hook SPTAuthLegacySession
- (void)productStateUpdated:(id)ps {
    appendToLog([NSString stringWithFormat:@"[AUTHlegacy] productStateUpdated class=%@\n", NSStringFromClass([ps class])]);
    %orig(mutateProductState(ps));
}
%end

%hook SPTExternalIntegrationArtistContentFactory
- (BOOL)isOnDemand {
    BOOL orig = %orig;
    appendToLog([NSString stringWithFormat:@"[onDemand] ArtistContentFactory orig=%d -> YES\n", orig]);
    return YES;
}
%end

// v55: inspecter la reponse UCS resolve (bootstrap config + feature flags)
static void dumpAssignedValues(id obj, NSString *tag) {
    @try {
        // Chercher un tableau de valeurs assignees via des clefs probables
        for (NSString *k in @[@"assignedValuesArray", @"assignedValues", @"configuration"]) {
            id v = nil;
            @try { v = [obj valueForKey:k]; } @catch (__unused NSException *e) {}
            if (!v) continue;
            id arr = v;
            if (![arr isKindOfClass:[NSArray class]]) {
                @try { arr = [v valueForKey:@"assignedValuesArray"]; } @catch (__unused NSException *e) {}
            }
            if ([arr isKindOfClass:[NSArray class]]) {
                for (id item in arr) {
                    NSString *name=nil; id bv=nil,ev=nil,iv=nil;
                    @try { name=[item valueForKey:@"name"]; } @catch(__unused NSException*e){}
                    @try { bv=[item valueForKey:@"boolValue"]; } @catch(__unused NSException*e){}
                    @try { ev=[item valueForKey:@"enumValue"]; } @catch(__unused NSException*e){}
                    @try { iv=[item valueForKey:@"intValue"]; } @catch(__unused NSException*e){}
                    if (name && ([[name lowercaseString] containsString:@"free"] ||
                                 [[name lowercaseString] containsString:@"ondemand"] ||
                                 [[name lowercaseString] containsString:@"on_demand"] ||
                                 [[name lowercaseString] containsString:@"on-demand"] ||
                                 [[name lowercaseString] containsString:@"shuffle"] ||
                                 [[name lowercaseString] containsString:@"reinvent"] ||
                                 [[name lowercaseString] containsString:@"premium"] ||
                                 [[name lowercaseString] containsString:@"catalog"])) {
                        appendToLog([NSString stringWithFormat:@"[cfg %@] %@ = b:%@ e:%@ i:%@\n", tag, name, bv, ev, iv]);
                    }
                }
            }
        }
    } @catch (__unused NSException *e) {}
}

%hook RCCFetchResponseHandler
- (void)handleResolveResponse:(id)response event:(id)event {
    appendToLog([NSString stringWithFormat:@"[resolve] class=%@\n", NSStringFromClass([response class])]);
    dumpAssignedValues(response, @"resp");
    @try {
        id cfg = [response valueForKey:@"configuration"];
        if (cfg) { appendToLog([NSString stringWithFormat:@"[resolve.cfg] class=%@\n", NSStringFromClass([cfg class])]); dumpAssignedValues(cfg, @"cfg"); }
    } @catch (__unused NSException *e) {}
    %orig;
}
%end

// v56: repliquer EeveeSpotify -> forcer la page artiste/album en on-demand (pistes jouables)
%hook SPTFreeTierArtistHubRemoteURLResolver
- (BOOL)isOnDemandTrialEnabled {
    appendToLog([NSString stringWithFormat:@"[artistHub] isOnDemandTrialEnabled orig=%d -> YES\n", %orig]);
    return YES;
}
- (BOOL)trackRowsEnabled {
    appendToLog([NSString stringWithFormat:@"[artistHub] trackRowsEnabled orig=%d -> YES\n", %orig]);
    return YES;
}
%end

%hook SPTFreeTierAlbumHubRemoteURLResolver
- (BOOL)isOnDemandTrialEnabled { return YES; }
- (BOOL)trackRowsEnabled { return YES; }
%end

%ctor {
    // v54: injecter le bnk premium DANS le process Spotify au chargement du tweak,
    // avant que l'app ne lise le cache -> le signal free-tier se calcule premium.
    @try {
        NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
        if (dirs.count) {
            NSString *bnkPath = [dirs[0] stringByAppendingPathComponent:@"PersistentCache/offline.bnk"];
            NSData *premium = [NSData dataWithContentsOfFile:@"/var/mobile/Documents/premium.bnk"];
            if (premium) {
                [[NSFileManager defaultManager] removeItemAtPath:bnkPath error:nil];
                BOOL ok = [premium writeToFile:bnkPath atomically:NO];
                appendToLog([NSString stringWithFormat:@"[bnk] ctor inject %lu bytes ok=%d -> %@\n", (unsigned long)premium.length, ok, bnkPath]);
            } else {
                appendToLog(@"[bnk] premium source NOT found\n");
            }
        }
    } @catch (NSException *e) {}
    appendToLog([NSString stringWithFormat:@"\n===== v54 loaded %@ =====\n", [NSDate date]]);
}

// v61: retirer la tab "Premium" du tab-bar (UI propre)
static NSArray *filterPremiumTab(NSArray *vcs) {
    if (![vcs isKindOfClass:[NSArray class]]) return vcs;
    NSMutableArray *out = [NSMutableArray array];
    for (UIViewController *vc in vcs) {
        NSString *title = vc.tabBarItem.title ?: (vc.title ?: @"");
        NSString *cls = NSStringFromClass([vc class]);
        NSString *rootCls = @"";
        @try {
            if ([vc isKindOfClass:[UINavigationController class]]) {
                UIViewController *root = [(UINavigationController *)vc viewControllers].firstObject;
                if (root) rootCls = NSStringFromClass([root class]);
            }
        } @catch (__unused NSException *e) {}
        BOOL isPremium = ([[title lowercaseString] containsString:@"premium"] ||
                          [cls containsString:@"PremiumDestination"] ||
                          [rootCls containsString:@"PremiumDestination"]);
        if (isPremium) {
            appendToLog([NSString stringWithFormat:@"[tabfilter] removed title=%@ cls=%@ root=%@\n", title, cls, rootCls]);
        } else {
            [out addObject:vc];
        }
    }
    return out;
}

%hook SPTAdaptiveTabBarController
- (void)setViewControllers:(NSArray *)vcs {
    %orig(filterPremiumTab(vcs));
}
%end

%hook SPTAdaptiveTabBarContainerViewController
- (void)setViewControllers:(NSArray *)vcs {
    %orig(filterPremiumTab(vcs));
}
- (void)setViewControllers:(NSArray *)vcs animated:(BOOL)animated {
    %orig(filterPremiumTab(vcs), animated);
}
%end

// v62: override GRAPHIQUE du libelle "Spotify Free" -> "Spotify Premium"
// (comme EeveeSpotify: reecrire le texte affiche, pas l'etat du compte)
static NSString *kFreeText = @"Spotify Free";
static NSString *kPremiumText = @"Spotify Premium";

%hook UILabel
- (void)setText:(NSString *)text {
    if ([text isKindOfClass:[NSString class]] && [text isEqualToString:kFreeText]) {
        %orig(kPremiumText);
        return;
    }
    %orig;
}
- (void)setAttributedText:(NSAttributedString *)attributedText {
    @try {
        if (attributedText.length && [[attributedText string] isEqualToString:kFreeText]) {
            NSDictionary *attrs = [attributedText attributesAtIndex:0 effectiveRange:NULL];
            NSAttributedString *rep = [[NSAttributedString alloc] initWithString:kPremiumText attributes:attrs];
            %orig(rep);
            return;
        }
    } @catch (__unused NSException *e) {}
    %orig;
}
%end

// ===== v66: LYRICS injectees dans la section native (remplace "Couldn't load") =====
static NSString *gTitle = nil;
static NSString *gArtist = nil;
static NSString *gLyricsText = nil;
static NSHashTable *gTVs = nil;             // toutes les vues paroles (refs faibles)
static NSMutableDictionary *gCache = nil;   // "artist|title" -> paroles
static NSMutableSet *gInFlight = nil;       // clefs en cours de requete
static char kEeveeTitleKey;
static char kEeveeGestKey;
static char kEeveeBtnKey;

static void eeveeSetText(UITextView *tv, NSString *text);
static NSString *eeveeStripLRC(NSString *s);
static double eeveeNowMs(void);

static void eeveeRegisterTV(UITextView *tv) {
    if (!gTVs) gTVs = [NSHashTable weakObjectsHashTable];
    [gTVs addObject:tv];
}

static NSString *eeveeKey(void) {
    return [NSString stringWithFormat:@"%@|%@", gArtist ?: @"", gTitle ?: @""];
}

static NSURLSession *eeveeSession(void) {
    static NSURLSession *s = nil; static dispatch_once_t o;
    dispatch_once(&o, ^{
        NSURLSessionConfiguration *c = [NSURLSessionConfiguration defaultSessionConfiguration];
        c.timeoutIntervalForRequest = 12.0;
        c.HTTPMaximumConnectionsPerHost = 6;
        c.connectionProxyDictionary = @{}; // ignorer tout proxy/VPN du systeme (erreur CFNetwork 310)
        s = [NSURLSession sessionWithConfiguration:c];
    });
    return s;
}

static void eeveeRefetchAll(void);

// extrait les paroles d'une reponse LRCLIB (dict de /get ou tableau de /search) ; nil si aucune
static NSString *eeveeParse(NSData *data) {
    if (!data) return nil;
    id j = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    NSDictionary *item = nil;
    if ([j isKindOfClass:[NSDictionary class]]) item = j;
    else if ([j isKindOfClass:[NSArray class]]) {
        for (NSDictionary *it in (NSArray *)j) {
            if (![it isKindOfClass:[NSDictionary class]]) continue;
            id sy = it[@"syncedLyrics"], pl = it[@"plainLyrics"];
            if (([sy isKindOfClass:[NSString class]] && [sy length]) ||
                ([pl isKindOfClass:[NSString class]] && [pl length])) { item = it; break; }
        }
    }
    if (!item) return nil;
    NSString *synced = item[@"syncedLyrics"], *plain = item[@"plainLyrics"];
    if ([synced isKindOfClass:[NSString class]] && synced.length) return eeveeStripLRC(synced);
    if ([plain isKindOfClass:[NSString class]] && plain.length) return plain;
    return nil;
}

static NSString *eeveeUA = @"EeveeLegacy v1 (Spotify lyrics tweak iOS13)";
static void eeveeGET(NSString *urlStr, void (^cb)(NSData *data, NSError *err)) {
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
    [req setValue:eeveeUA forHTTPHeaderField:@"User-Agent"];
    NSURLSessionDataTask *t = [eeveeSession() dataTaskWithRequest:req
        completionHandler:^(NSData *d, NSURLResponse *r, NSError *e) { cb(d, e); }];
    [t resume];
}

static void eeveeFinish(NSString *key, NSString *text) {
    dispatch_async(dispatch_get_main_queue(), ^{
        appendToLog([NSString stringWithFormat:@"[fetchdone %.0f] %@ len=%lu\n", eeveeNowMs(), key, (unsigned long)(text ? text.length : 0)]);
        if (!gCache) gCache = [NSMutableDictionary dictionary];
        gCache[key] = text ?: @"No lyrics found for this song";
        [gInFlight removeObject:key];
        eeveeRefetchAll();
    });
}
static void eeveeAbort(NSString *key) { // erreur reseau : NE PAS cacher -> retry possible
    dispatch_async(dispatch_get_main_queue(), ^{ [gInFlight removeObject:key]; });
}

// /api/get (rapide) puis /api/search (secours) ; erreurs reseau non cachees
static void eeveeNetFetch(NSString *key, NSString *title, NSString *artist) {
    if (!key.length || !title.length) return;
    if (!gInFlight) gInFlight = [NSMutableSet set];
    if ([gInFlight containsObject:key]) return; // single-flight
    [gInFlight addObject:key];
    NSCharacterSet *cs = [NSCharacterSet URLQueryAllowedCharacterSet];
    NSString *ea = [artist stringByAddingPercentEncodingWithAllowedCharacters:cs];
    NSString *et = [title stringByAddingPercentEncodingWithAllowedCharacters:cs];
    NSString *getURL = [NSString stringWithFormat:@"https://lrclib.net/api/get?artist_name=%@&track_name=%@", ea, et];
    NSString *searchURL = [NSString stringWithFormat:@"https://lrclib.net/api/search?artist_name=%@&track_name=%@", ea, et];
    appendToLog([NSString stringWithFormat:@"[fetchstart %.0f] %@\n", eeveeNowMs(), title]);
    eeveeGET(getURL, ^(NSData *d, NSError *e) {
        if (e) { appendToLog([NSString stringWithFormat:@"[neterr get] %@ %@\n", title, e.localizedDescription]); eeveeAbort(key); return; }
        NSString *lyr = eeveeParse(d);
        if (lyr.length) { eeveeFinish(key, lyr); return; }
        // secours : recherche floue
        eeveeGET(searchURL, ^(NSData *d2, NSError *e2) {
            if (e2) { appendToLog([NSString stringWithFormat:@"[neterr search] %@ %@\n", title, e2.localizedDescription]); eeveeAbort(key); return; }
            eeveeFinish(key, eeveeParse(d2));
        });
    });
}

// applique le cache aux vues visibles, sinon lance UNE requete
static void eeveeRefetchAll(void) {
    if (!gTVs || !gTitle.length) return;
    NSString *key = eeveeKey(); // artiste|titre : change si l'artiste arrive apres le titre
    NSString *cached = gCache[key];
    BOOL needFetch = NO;
    for (UITextView *tv in [gTVs allObjects]) {
        if (!tv.window) continue;
        NSString *shown = objc_getAssociatedObject(tv, &kEeveeTitleKey);
        if ([shown isEqualToString:key]) continue; // deja a jour pour CETTE clef
        if (cached) {
            objc_setAssociatedObject(tv, &kEeveeTitleKey, key, OBJC_ASSOCIATION_COPY_NONATOMIC);
            eeveeSetText(tv, cached);
        } else {
            eeveeSetText(tv, @"Loading lyrics…");
            needFetch = YES;
        }
    }
    // ne lancer la requete qu'une fois l'artiste connu (evite le fetch a clef vide au demarrage)
    if (needFetch && !cached && gArtist.length) eeveeNetFetch(key, gTitle, gArtist);
}

// timer avec debounce : ne rafraichit que quand le morceau s'est STABILISE
// (evite une requete par morceau quand on zappe vite)
static NSString *gPrevTick = nil;
static double eeveeNowMs(void) { return [[NSDate date] timeIntervalSince1970] * 1000.0; }
static void eeveeStartTimer(void) {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        [NSTimer scheduledTimerWithTimeInterval:0.5 repeats:YES block:^(NSTimer *t) {
            BOOL stable = (gTitle.length && [gTitle isEqualToString:gPrevTick]);
            appendToLog([NSString stringWithFormat:@"[tick %.0f] title=%@ stable=%d\n", eeveeNowMs(), gTitle, stable]);
            if (stable) eeveeRefetchAll();
            gPrevTick = [gTitle copy];
        }];
    });
}

// les hooks ne declenchent plus de fetch immediat : c'est le timer debounce qui gere
static void eeveeMaybeRefetch(void) { }

static NSString *strFrom(id v) {
    if ([v isKindOfClass:[NSString class]]) return v;
    if ([v isKindOfClass:[NSAttributedString class]]) return [(NSAttributedString *)v string];
    return nil;
}

%hook SPTNowPlayingInformationUnitViewModelImplementation
- (id)title { id t = %orig; NSString *s = strFrom(t); if (s.length) gTitle = [s copy]; return t; }
- (id)subtitle {
    id t = %orig; NSString *s = strFrom(t);
    if (s.length) {
        NSRange r = [s rangeOfString:@"•"];
        if (r.location != NSNotFound) s = [s substringToIndex:r.location];
        gArtist = [[s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] copy];
        eeveeMaybeRefetch(); // le subtitle arrive avec titre+artiste frais -> refetch au changement de morceau
    }
    return t;
}
%end

// source de titre fiable : la barre du lecteur change a chaque skip
%hook SPTNowPlayingBarPageView
- (id)title { id t = %orig; NSString *s = strFrom(t); if (s.length) gTitle = [s copy]; return t; }
- (id)subtitle {
    id t = %orig; NSString *s = strFrom(t);
    if (s.length) {
        NSRange r = [s rangeOfString:@"•"];
        if (r.location != NSNotFound) s = [s substringToIndex:r.location];
        gArtist = [[s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] copy];
        eeveeMaybeRefetch();
    }
    return t;
}
%end

static NSString *eeveeStripLRC(NSString *s) {
    NSError *e = nil;
    NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:@"\\[\\d{1,2}:\\d{2}(\\.\\d{1,3})?\\]" options:0 error:&e];
    return re ? [re stringByReplacingMatchesInString:s options:0 range:NSMakeRange(0, s.length) withTemplate:@""] : s;
}

static void eeveeSetText(UITextView *tv, NSString *text) {
    NSMutableParagraphStyle *ps = [NSMutableParagraphStyle new];
    ps.alignment = NSTextAlignmentCenter;
    ps.lineSpacing = 7.0;
    tv.attributedText = [[NSAttributedString alloc] initWithString:text attributes:@{
        NSFontAttributeName: [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold],
        NSForegroundColorAttributeName: [UIColor whiteColor],
        NSParagraphStyleAttributeName: ps
    }];
    tv.contentOffset = CGPointZero;
    gLyricsText = [text copy];
}

// plein ecran "a nous" (le bouton natif est verrouille sans lyrics natives)
static UIViewController *eeveeTopVC(void) {
    UIWindow *key = nil;
    NSArray *wins = [UIApplication sharedApplication].windows;
    for (UIWindow *w in wins) { if (w.isKeyWindow) { key = w; break; } }
    if (!key) key = wins.firstObject;
    UIViewController *vc = key.rootViewController;
    while (vc.presentedViewController) vc = vc.presentedViewController;
    return vc;
}

static void eeveeDoExpand(UIViewController *presenter) {
    if (!presenter) presenter = eeveeTopVC();
    if (!presenter) return;
    UIViewController *full = [UIViewController new];
    full.modalPresentationStyle = UIModalPresentationOverFullScreen;
    full.view.backgroundColor = [UIColor colorWithWhite:0.03 alpha:1.0];
    UITextView *tv = [[UITextView alloc] initWithFrame:full.view.bounds];
    tv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    tv.backgroundColor = [UIColor clearColor];
    tv.editable = NO;
    tv.selectable = NO;
    tv.textContainerInset = UIEdgeInsetsMake(72, 24, 60, 24);
    tv.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    NSMutableParagraphStyle *ps = [NSMutableParagraphStyle new];
    ps.alignment = NSTextAlignmentCenter; ps.lineSpacing = 9.0;
    tv.attributedText = [[NSAttributedString alloc] initWithString:(gLyricsText ?: @"") attributes:@{
        NSFontAttributeName: [UIFont systemFontOfSize:22 weight:UIFontWeightSemibold],
        NSForegroundColorAttributeName: [UIColor whiteColor],
        NSParagraphStyleAttributeName: ps }];
    [full.view addSubview:tv];
    eeveeRegisterTV(tv);
    objc_setAssociatedObject(tv, &kEeveeTitleKey, gTitle, OBJC_ASSOCIATION_COPY_NONATOMIC);
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:presenter action:@selector(eeveeCloseFull:)];
    tap.numberOfTapsRequired = 2;
    [full.view addGestureRecognizer:tap];
    // croix de fermeture (haut droite)
    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    close.frame = CGRectMake(full.view.bounds.size.width - 54, 50, 42, 42);
    close.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [close setTitle:@"✕" forState:UIControlStateNormal];
    close.titleLabel.font = [UIFont systemFontOfSize:26 weight:UIFontWeightBold];
    [close setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [close addTarget:presenter action:@selector(eeveeCloseFull:) forControlEvents:UIControlEventTouchUpInside];
    [full.view addSubview:close];
    [presenter presentViewController:full animated:YES completion:nil];
}

// le bouton "agrandir" est un EncoreButton (UIControl, pas UIButton) en haut a droite.
// on prend le controle le plus a DROITE de la zone d'en-tete.
static void eeveeCollectTop(UIView *root, UIView *cs, UIControl **best, CGFloat *bestX) {
    for (UIView *sub in root.subviews) {
        if ([sub isKindOfClass:[UIControl class]]) {
            CGRect f = [sub convertRect:sub.bounds toView:cs];
            if (f.origin.y < 64 && f.size.width > 8 && f.size.width < 80 && f.size.height > 8 &&
                CGRectGetMinX(f) > *bestX) {
                *bestX = CGRectGetMinX(f);
                *best = (UIControl *)sub;
            }
        }
        eeveeCollectTop(sub, cs, best, bestX);
    }
}
static UIControl *eeveeFindExpandButton(UIView *root, UIView *coordSpace) {
    UIControl *best = nil; CGFloat bestX = -1;
    eeveeCollectTop(root, coordSpace, &best, &bestX);
    return best;
}

static void eeveeFetchLyrics(UITextView *tv) {
    if (!gTitle.length) { eeveeSetText(tv, @"No track detected"); return; }
    NSString *key = eeveeKey();
    NSString *cached = gCache ? gCache[key] : nil;
    if (cached) { eeveeSetText(tv, cached); return; }
    eeveeSetText(tv, @"Loading lyrics…");
    eeveeNetFetch(key, gTitle, gArtist);
}

// masque la vue d'erreur native ("Couldn't load") recursivement
static void eeveeHideNativeError(UIView *v) {
    for (UIView *sub in v.subviews) {
        NSString *cls = NSStringFromClass([sub class]);
        if ([cls containsString:@"ErrorView"]) { sub.hidden = YES; continue; }
        eeveeHideNativeError(sub);
    }
}

// injecte notre textview dans un VC lyrics, sous l'en-tete, refetch au changement de morceau
static void eeveeInjectLyrics(UIViewController *vc) {
    UIView *v = vc.view;
    eeveeHideNativeError(v);
    UITextView *tv = (UITextView *)[v viewWithTag:99125];
    if (!tv) {
        tv = [[UITextView alloc] initWithFrame:v.bounds];
        tv.tag = 99125;
        tv.backgroundColor = [UIColor clearColor];
        tv.editable = NO;
        tv.selectable = NO;
        tv.textContainerInset = UIEdgeInsetsMake(28, 20, 28, 20);
        tv.indicatorStyle = UIScrollViewIndicatorStyleWhite;
        [v addSubview:tv];
    }
    CGFloat topInset = 54.0; // laisser l'en-tete "Lyrics" + bouton fullscreen visibles
    tv.frame = CGRectMake(0, topInset, v.bounds.size.width, v.bounds.size.height - topInset);
    [v bringSubviewToFront:tv];
    eeveeRegisterTV(tv); eeveeStartTimer();
    // double-tap sur les paroles -> plein ecran
    if (!objc_getAssociatedObject(tv, &kEeveeGestKey)) {
        UITapGestureRecognizer *dt = [[UITapGestureRecognizer alloc] initWithTarget:vc action:@selector(eeveeExpand:)];
        dt.numberOfTapsRequired = 2;
        [tv addGestureRecognizer:dt];
        objc_setAssociatedObject(tv, &kEeveeGestKey, @1, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    // accrocher notre action au bouton "agrandir" natif (qui ne fait rien)
    if (!objc_getAssociatedObject(v, &kEeveeBtnKey)) {
        UIControl *btn = eeveeFindExpandButton(v, v);
        if (btn) {
            [btn addTarget:vc action:@selector(eeveeExpand:) forControlEvents:UIControlEventTouchUpInside];
            objc_setAssociatedObject(v, &kEeveeBtnKey, @1, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
    NSString *shown = objc_getAssociatedObject(tv, &kEeveeTitleKey);
    if (gTitle.length && ![shown isEqualToString:gTitle]) {
        objc_setAssociatedObject(tv, &kEeveeTitleKey, gTitle, OBJC_ASSOCIATION_COPY_NONATOMIC);
        eeveeFetchLyrics(tv);
    }
}

%hook _TtC15Lyrics_CoreImpl20LyricsViewController
- (void)viewDidLayoutSubviews { %orig; eeveeInjectLyrics((UIViewController *)self); }
%new
- (void)eeveeExpand:(id)s { eeveeDoExpand((UIViewController *)self); }
%new
- (void)eeveeCloseFull:(id)g { [((UIViewController *)self) dismissViewControllerAnimated:YES completion:nil]; }
%end

%hook _TtC15Lyrics_CoreImpl18CardViewController
- (void)viewDidLayoutSubviews { %orig; eeveeInjectLyrics((UIViewController *)self); }
%new
- (void)eeveeExpand:(id)s { eeveeDoExpand((UIViewController *)self); }
%new
- (void)eeveeCloseFull:(id)g { [((UIViewController *)self) dismissViewControllerAnimated:YES completion:nil]; }
%end

%hook _TtC15Lyrics_CoreImpl24FullscreenViewController
- (void)viewDidLayoutSubviews { %orig; eeveeInjectLyrics((UIViewController *)self); }
%new
- (void)eeveeExpand:(id)s { eeveeDoExpand((UIViewController *)self); }
%new
- (void)eeveeCloseFull:(id)g { [((UIViewController *)self) dismissViewControllerAnimated:YES completion:nil]; }
%end
