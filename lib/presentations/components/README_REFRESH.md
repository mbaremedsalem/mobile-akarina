# Guide d'utilisation des widgets de rafraîchissement

Ce guide explique comment ajouter la fonctionnalité de pull-to-refresh à toutes les pages de votre application Akarina.

## Widgets disponibles

### 1. RefreshableWidget
Widget générique pour envelopper n'importe quel widget avec la fonctionnalité de rafraîchissement.

```dart
import 'package:akarina/presentations/components/refreshable_widget.dart';

RefreshableWidget(
  onRefresh: () async {
    // Votre fonction de rafraîchissement ici
    await fetchData();
  },
  child: YourWidget(),
)
```

### 2. RefreshableScrollView
Spécialement conçu pour les pages utilisant CustomScrollView avec des slivers.

```dart
RefreshableScrollView(
  onRefresh: () async {
    await fetchData();
  },
  slivers: [
    SliverToBoxAdapter(child: YourWidget()),
    SliverList(delegate: SliverChildBuilderDelegate(...)),
  ],
)
```

### 3. RefreshableListView
Pour les pages avec ListView simple.

```dart
RefreshableListView(
  onRefresh: () async {
    await fetchData();
  },
  children: [
    Widget1(),
    Widget2(),
    Widget3(),
  ],
)
```

### 4. RefreshableGridView
Pour les pages avec GridView.

```dart
RefreshableGridView(
  onRefresh: () async {
    await fetchData();
  },
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
  ),
  children: [
    GridItem1(),
    GridItem2(),
    // ...
  ],
)
```

## Exemples d'implémentation

### Page d'accueil (Home)
```dart
// Dans lib/presentations/screens/home/home.dart
body: SafeArea(
  child: RefreshIndicator(
    onRefresh: () async {
      await Future.wait([
        _loadResidenciel(),
        _loadCategories(),
        _loadProximite(),
        fetchCities(),
      ]);
    },
    child: CustomScrollView(
      slivers: [
        // Vos slivers ici
      ],
    ),
  ),
),
```

### Page Appartement
```dart
// Dans lib/presentations/screens/appartement/appartement.dart
Expanded(
  child: RefreshableWidget(
    onRefresh: () async {
      await _loadApartments();
    },
    child: GridView.builder(
      // Votre GridView ici
    ),
  ),
),
```

### Page Détails Immobilier
```dart
// Dans lib/presentations/screens/immobillier/immob_details.dart
body: SafeArea(
  child: RefreshableWidget(
    onRefresh: () async {
      await fetchImmobDetails();
    },
    child: SingleChildScrollView(
      // Votre contenu ici
    ),
  ),
),
```

### Page Profil
```dart
// Dans lib/presentations/screens/profile/profile.dart
Padding(
  padding: const EdgeInsets.only(top: 200),
  child: RefreshableWidget(
    onRefresh: () async {
      await fetchUserData();
    },
    child: SingleChildScrollView(
      // Votre contenu ici
    ),
  ),
),
```

## Bonnes pratiques

1. **Gestion des erreurs** : Toujours gérer les erreurs dans vos fonctions de rafraîchissement
2. **État de chargement** : Utilisez setState pour mettre à jour l'état de chargement
3. **Vérification du mounted** : Vérifiez si le widget est toujours monté avant de mettre à jour l'état
4. **Feedback utilisateur** : Affichez des messages de succès ou d'erreur avec ScaffoldMessenger

## Exemple complet de fonction de rafraîchissement

```dart
Future<void> refreshData() async {
  if (!mounted) return;
  
  setState(() {
    isLoading = true;
  });

  try {
    // Vos appels API ici
    await fetchDataFromAPI();
    
    if (!mounted) return;
    
    setState(() {
      isLoading = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Données rafraîchies avec succès')),
    );
  } catch (e) {
    if (!mounted) return;
    
    setState(() {
      isLoading = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur lors du rafraîchissement: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

## Pages à mettre à jour

Voici la liste des pages principales qui devraient avoir la fonctionnalité de rafraîchissement :

- ✅ Home (déjà implémenté)
- ✅ Appartement (déjà implémenté)
- ✅ ImmobDetails (déjà implémenté)
- ✅ Profile (déjà implémenté)
- 🔄 Notification
- 🔄 Chat
- 🔄 Cart
- 🔄 Category
- 🔄 Localisation
- 🔄 Statistique
- 🔄 Inform

## Notes importantes

- Le RefreshIndicator ne fonctionne que si le contenu est scrollable
- Pour les pages avec des widgets fixes, utilisez RefreshableWidget
- Assurez-vous que vos fonctions de rafraîchissement sont asynchrones
- Testez toujours la fonctionnalité sur différents appareils 